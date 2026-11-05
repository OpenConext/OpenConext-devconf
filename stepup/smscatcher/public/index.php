<?php

/**
 * SMSCatcher - a "mailcatcher for SMS" that emulates the Spryng REST API v1.
 *
 * This is a testing tool, not intended for production use.
 *
 * Captures every SMS the app "sends" instead of delivering it, shows them in a
 * web UI (like Mailcatcher does for e-mail) and exposes a JSON API so tests can
 * assert on the messages (e.g. read the OTP code from the SMS body).
 *
 * Endpoints:
 *   Spryng REST API v1 (used by OpenConext Stepup-Gateway via the spryng/rest-api-php composer module):
 *     POST /v1/messages                 create (send) a message
 *     GET  /v1/messages                 list (supports filters[...], limit, page)
 *     GET  /v1/messages/{id}            show one message
 *     POST /v1/messages/{id}/cancel     cancel a scheduled message
 *     GET  /v1/balance                  fake balance
 *   Spryng "simple" HTTP API (legacy):
 *     GET|POST /api/simple/message      ?destination=&sender=&body=...  (returns "1" on success)
 *   Mailcatcher-style UI / JSON API:
 *     GET    /                          web UI inbox
 *     GET    /messages                  JSON list of all captured messages
 *     GET    /api/messages              JSON list (same as /messages)
 *     GET    /api/messages/{id}         JSON detail of one message
 *     DELETE /api/messages/{id}         delete one message
 *     DELETE /api/messages              delete all messages
 *     POST   /api/messages/delete       delete all (HTML form fallback), redirects to /
 *     GET    /api/health                {"status": "ok"}
 *
 * Configuration (environment variables):
 *   SPRYNG_API_KEY            if set, /v1/* requires "Authorization: Bearer <this key>";
 *                             otherwise any non-empty Bearer token is accepted
 *   SMSCATCHER_PERSIST_PATH   JSON file used to store captured messages
 *                             (default /tmp/smscatcher-messages.json)
 */

declare(strict_types=1);

const RATE_LIMIT = 1200;  // Rate limit used for faking X-RateLimit-* headers
const BALANCE = 100.0;    // Balance amount returned by /v1/balance

/* ------------------------------------------------------------------------ */
/* helpers                                                                   */
/* ------------------------------------------------------------------------ */

function env(string $name, ?string $default = null): ?string
{
    if (isset($_SERVER[$name])) {
        return (string) $_SERVER[$name];
    }
    if (isset($_ENV[$name])) {
        return (string) $_ENV[$name];
    }
    $value = getenv($name);
    return $value === false ? $default : $value;
}

function storePath(): string
{
    return env('SMSCATCHER_PERSIST_PATH', '/tmp/smscatcher-messages.json');
}

/** Read all captured messages (shared lock). */
function readStore(): array
{
    $path = storePath();
    if (!is_file($path)) {
        return [];
    }
    $fp = fopen($path, 'r');
    if (!$fp) {
        return [];
    }
    flock($fp, LOCK_SH);
    $raw = stream_get_contents($fp);
    flock($fp, LOCK_UN);
    fclose($fp);
    $messages = $raw ? json_decode($raw, true) : [];
    return is_array($messages) ? $messages : [];
}

/** Apply $fn(&$messages) under an exclusive lock and persist the result. Returns the messages. */
function updateStore(callable $fn): array
{
    $path = storePath();
    $fp = fopen($path, 'c+');
    if (!$fp) {
        $messages = [];
        $fn($messages);
        return $messages;
    }
    flock($fp, LOCK_EX);
    $raw = stream_get_contents($fp);
    $messages = $raw ? (json_decode($raw, true) ?: []) : [];
    if (!is_array($messages)) {
        $messages = [];
    }
    $fn($messages);
    ftruncate($fp, 0);
    rewind($fp);
    fwrite($fp, json_encode(array_values($messages), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    fflush($fp);
    flock($fp, LOCK_UN);
    fclose($fp);
    return $messages;
}

function uuid4(): string
{
    $b = random_bytes(16);
    $b[6] = chr((ord($b[6]) & 0x0f) | 0x40);
    $b[8] = chr((ord($b[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($b), 4));
}

function nowIso(): string
{
    return gmdate('Y-m-d\TH:i:s+00:00');
}

function h(?string $s): string
{
    return htmlspecialchars((string) $s, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function sendJson(int $code, $data, array $headers = []): void
{
    http_response_code($code);
    header('Content-Type: application/json');
    foreach ($headers as $name => $value) {
        header($name . ': ' . $value);
    }
    echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
}

function sendText(int $code, string $text, string $contentType = 'text/plain; charset=utf-8'): void
{
    http_response_code($code);
    header('Content-Type: ' . $contentType);
    echo $text;
}

function sendHtml(int $code, string $html): void
{
    http_response_code($code);
    header('Content-Type: text/html; charset=utf-8');
    echo $html;
}

function rateHeaders(): array
{
    return [
        'X-RateLimit-Limit' => (string) RATE_LIMIT,
        'X-RateLimit-Remaining' => (string) (RATE_LIMIT - 1),
    ];
}

function requestPath(): string
{
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    return rtrim($path, '/') ?: '/';
}

function bearerToken(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if ($header === '' && function_exists('apache_request_headers')) {
        $headers = array_change_key_case(apache_request_headers(), CASE_LOWER);
        $header = $headers['authorization'] ?? '';
    }
    if (preg_match('/^Bearer\s+(\S+)\s*$/i', $header, $m)) {
        return $m[1];
    }
    return null;
}

/** Spryng-style Bearer auth. Sends 401 and returns false when not authorized. */
function authorized(): bool
{
    $expected = env('SPRYNG_API_KEY');
    $token = bearerToken();
    if ($token === null) {
        sendJson(401, ['message' => 'Unauthenticated.'], rateHeaders());
        return false;
    }
    if ($expected !== null && $expected !== '' && !hash_equals($expected, $token)) {
        sendJson(401, ['message' => 'Unauthenticated.'], rateHeaders());
        return false;
    }
    return true;
}

/** Parsed request body: JSON when sent as application/json, form fields otherwise. */
function readBody(): array
{
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (str_contains($contentType, 'application/json')) {
        $data = json_decode((string) file_get_contents('php://input'), true);
        return is_array($data) ? $data : [];
    }
    return $_POST;
}

function addMessage(string $originator, array $recipients, string $body, ?string $route = null,
                    ?string $encoding = null, ?string $reference = null, ?string $scheduledAt = null,
                    string $via = 'spryng-rest'): array
{
    $message = [
        'id' => uuid4(),
        'encoding' => $encoding ?: 'auto',
        'body' => $body,
        'route' => $route ?: 'business',
        'originator' => $originator,
        'recipients' => array_values($recipients),
        'reference' => $reference,
        'credits' => count($recipients),
        'status' => $scheduledAt ? 'scheduled' : 'send',
        'scheduled_at' => $scheduledAt,
        'created_at' => nowIso(),
        'updated_at' => nowIso(),
        'via' => $via,
        'links' => [],
    ];
    $message['links']['self'] = '/v1/messages/' . $message['id'];
    updateStore(function (array &$messages) use ($message): void {
        $messages[] = $message;
    });
    return $message;
}

/* ------------------------------------------------------------------------ */
/* Spryng REST API v1 handlers                                               */
/* ------------------------------------------------------------------------ */

function spryngCreate(): void
{
    $data = readBody();
    $errors = [];
    $body = $data['body'] ?? null;
    $originator = $data['originator'] ?? null;
    $recipients = $data['recipients'] ?? null;

    if (!$body || !is_string($body)) {
        $errors['body'] = ['The body field is required.'];
    }
    if (!$originator || !is_string($originator)) {
        $errors['originator'] = ['The originator field is required.'];
    }
    if (!is_array($recipients) || $recipients === []
        || !array_reduce($recipients, fn($ok, $r) => $ok && is_string($r) && $r !== '', true)
    ) {
        $errors['recipients'] = ['The recipients field is required and must be a non-empty array.'];
    }
    if ($errors !== []) {
        sendJson(422, ['message' => 'Missing or invalid parameters.', 'errors' => $errors], rateHeaders());
        return;
    }

    $message = addMessage(
        $originator,
        $recipients,
        $body,
        isset($data['route']) ? (string) $data['route'] : null,
        isset($data['encoding']) ? (string) $data['encoding'] : null,
        isset($data['reference']) ? (string) $data['reference'] : null,
        isset($data['scheduled_at']) ? (string) $data['scheduled_at'] : null,
        'spryng-rest'
    );
    sendJson(201, $message, rateHeaders());
}

function spryngList(): void
{
    $messages = array_reverse(readStore());
    // PHP parses query strings like filters[status]=send into $_GET['filters']['status']
    $filters = $_GET['filters'] ?? [];
    if (!is_array($filters)) {
        $filters = [];
    }
    $filters = array_map('strval', $filters);
    if (isset($filters['status'])) {
        $messages = array_values(array_filter($messages, fn($m) => ($m['status'] ?? '') === $filters['status']));
    }
    if (isset($filters['originator'])) {
        $messages = array_values(array_filter($messages, fn($m) => ($m['originator'] ?? '') === $filters['originator']));
    }
    if (isset($filters['reference'])) {
        $messages = array_values(array_filter($messages, fn($m) => ($m['reference'] ?? null) === $filters['reference']));
    }
    if (isset($filters['recipient_number'])) {
        $messages = array_values(array_filter(
            $messages,
            fn($m) => in_array($filters['recipient_number'], $m['recipients'] ?? [], true)
        ));
    }
    $limit = max(1, (int) ($_GET['limit'] ?? 15));
    $page = max(1, (int) ($_GET['page'] ?? 1));
    $total = count($messages);
    $messages = array_slice($messages, ($page - 1) * $limit, $limit);
    sendJson(200, ['data' => $messages, 'meta' => ['total' => $total, 'page' => $page, 'limit' => $limit]],
        rateHeaders());
}

function findMessage(string $id): ?array
{
    foreach (readStore() as $message) {
        if (($message['id'] ?? '') === $id) {
            return $message;
        }
    }
    return null;
}

function spryngShow(string $id): void
{
    $message = findMessage($id);
    if ($message !== null) {
        sendJson(200, $message, rateHeaders());
        return;
    }
    sendJson(404, ['message' => 'No message with that ID.'], rateHeaders());
}

function spryngCancel(string $id): void
{
    $found = null;
    updateStore(function (array &$messages) use ($id, &$found): void {
        foreach ($messages as &$message) {
            if (($message['id'] ?? '') === $id) {
                $message['status'] = 'cancelled';
                $message['updated_at'] = nowIso();
                $found = $message;
            }
        }
        unset($message);
    });
    if ($found !== null) {
        sendJson(200, $found, rateHeaders());
        return;
    }
    sendJson(404, ['message' => 'No message with that ID.'], rateHeaders());
}

/* ------------------------------------------------------------------------ */
/* Spryng simple HTTP API (legacy)                                           */
/* ------------------------------------------------------------------------ */

function simpleApi(): void
{
    $params = array_merge($_GET, $_POST);
    foreach (['destination', 'sender', 'body'] as $required) {
        if (empty($params[$required])) {
            // Spryng simple API return code 100 = missing parameter
            sendText(200, '100');
            return;
        }
    }
    addMessage(
        (string) $params['sender'],
        [(string) $params['destination']],
        (string) $params['body'],
        isset($params['route']) ? (string) $params['route'] : null,
        null,
        isset($params['reference']) ? (string) $params['reference'] : null,
        null,
        'spryng-simple'
    );
    // Spryng simple API returns "1" on success
    sendText(200, '1');
}

/* ------------------------------------------------------------------------ */
/* web UI                                                                    */
/* ------------------------------------------------------------------------ */

function renderUi(): void
{
    $messages = array_reverse(readStore());
    $rows = [];
    foreach ($messages as $m) {
        $rows[] = '<tr><td class="meta">' . h($m['created_at'] ?? '') . '</td>'
            . '<td>' . h(implode(', ', $m['recipients'] ?? [])) . '</td>'
            . '<td>' . h($m['originator'] ?? '') . '</td>'
            . '<td class="body">' . h($m['body'] ?? '') . '</td>'
            . '<td>' . h($m['route'] ?? '') . '</td>'
            . '<td class="meta">' . h($m['reference'] ?? '') . '</td>'
            . '<td class="meta">' . h($m['status'] ?? '') . '</td></tr>';
    }
    $count = count($messages);
    $html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="5">
<title>SMSCatcher</title>
<style>
 body { font-family: -apple-system, Segoe UI, Roboto, sans-serif; margin: 2em; background: #f6f8fa; color: #24292f; }
 h1 { font-size: 1.4em; }
 .bar { display: flex; justify-content: space-between; align-items: center; }
 table { border-collapse: collapse; width: 100%; background: #fff; }
 th, td { border: 1px solid #d0d7de; padding: 6px 10px; text-align: left; vertical-align: top; }
 th { background: #eaeef2; }
 td.body { white-space: pre-wrap; font-family: ui-monospace, monospace; }
 .meta { color: #57606a; font-size: 0.85em; }
 button { padding: 6px 12px; }
</style>
</head>
<body>
<div class="bar">
  <h1>&#128233; SMSCatcher &mdash; captured SMS</h1>
  <form method="post" action="/api/messages/delete"><button type="submit">Clear all</button></form>
</div>
<p class="meta">{$count} message(s). JSON API: <a href="/api/messages">/api/messages</a> &middot; Spryng API: <code>POST /v1/messages</code></p>
<table>
<tr><th>Time</th><th>To</th><th>From</th><th>Body</th><th>Route</th><th>Ref</th><th>Status</th></tr>
HTML . "\n" . implode("\n", $rows) . <<<HTML

</table>
</body>
</html>
HTML;
    sendHtml(200, $html);
}

/* ------------------------------------------------------------------------ */
/* router                                                                    */
/* ------------------------------------------------------------------------ */

$method = $_SERVER['REQUEST_METHOD'];
$path = requestPath();

// UI / health / JSON API
if ($path === '/' && $method === 'GET') {
    renderUi();
    return;
}
if (in_array($path, ['/api/health', '/health'], true) && $method === 'GET') {
    sendJson(200, ['status' => 'ok']);
    return;
}
if (in_array($path, ['/messages', '/api/messages'], true) && $method === 'GET') {
    sendJson(200, array_reverse(readStore()));
    return;
}
if (preg_match('#^/api/messages/([0-9a-f-]{36})$#', $path, $m)) {
    if ($method === 'GET') {
        $message = findMessage($m[1]);
        if ($message !== null) {
            sendJson(200, $message);
        } else {
            sendJson(404, ['message' => 'Message not found.']);
        }
        return;
    }
    if ($method === 'DELETE') {
        $deleted = false;
        updateStore(function (array &$messages) use ($m, &$deleted): void {
            foreach ($messages as $i => $message) {
                if (($message['id'] ?? '') === $m[1]) {
                    unset($messages[$i]);
                    $deleted = true;
                }
            }
        });
        sendJson($deleted ? 200 : 404, $deleted ? ['deleted' => $m[1]] : ['message' => 'Message not found.']);
        return;
    }
}
if ($path === '/api/messages' && $method === 'DELETE') {
    updateStore(function (array &$messages): void {
        $messages = [];
    });
    sendJson(200, ['deleted' => 'all']);
    return;
}
if ($path === '/api/messages/delete' && $method === 'POST') {
    updateStore(function (array &$messages): void {
        $messages = [];
    });
    http_response_code(303);
    header('Location: /');
    return;
}

// Spryng simple HTTP API (legacy)
if ($path === '/api/simple/message' && in_array($method, ['GET', 'POST'], true)) {
    simpleApi();
    return;
}

// Spryng REST API v1
if (str_starts_with($path, '/v1/')) {
    if (!authorized()) {
        return;
    }
    if ($path === '/v1/messages' && $method === 'POST') {
        spryngCreate();
        return;
    }
    if ($path === '/v1/messages' && $method === 'GET') {
        spryngList();
        return;
    }
    if (preg_match('#^/v1/messages/([0-9a-f-]{36})$#', $path, $m) && $method === 'GET') {
        spryngShow($m[1]);
        return;
    }
    if (preg_match('#^/v1/messages/([0-9a-f-]{36})/cancel$#', $path, $m) && $method === 'POST') {
        spryngCancel($m[1]);
        return;
    }
    if ($path === '/v1/balance' && $method === 'GET') {
        sendJson(200, ['balance' => ['amount' => BALANCE, 'currency' => 'EUR']], rateHeaders());
        return;
    }
    if ($method === 'POST') {
        sendJson(405, ['message' => 'Method not allowed.'], rateHeaders());
        return;
    }
    sendJson(404, ['message' => 'Not found.'], rateHeaders());
    return;
}

sendText(404, "Not found. See / for the UI.\n");
