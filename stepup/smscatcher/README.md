# SMSCatcher — the mailcatcher for SMS

A small, dependency-free **PHP** mock of the **Spryng REST API v1** (the API
OpenConext Stepup-Gateway uses through `spryng/rest-api-php`). Instead of
sending real SMS, it captures every message and shows it in a web UI, exactly
like Mailcatcher does for e-mail. A JSON API is included so Behat tests can
read the OTP code out of the captured SMS.

It runs on a base image from the project:
`ghcr.io/openconext/openconext-basecontainers/php85-apache2`
It is an Apache + mod_php, with single front controller `public/index.php`. Captured messages are stored in a lock-protected JSON file (`SMSCATCHER_PERSIST_PATH`, default
`/tmp/smscatcher-messages.json` inside the container).

## Run it

Via the stepup devconf stack (see `../docker-compose.yml`):

```shell
./start-dev-env.sh          # starts smscatcher together with the other services
```

Or standalone:

```shell
docker build -t smscatcher ./stepup/smscatcher
docker run -p 1090:80 smscatcher
```

- Web UI: <http://localhost:1090> (in devconf also <https://smscatcher.dev.openconext.local>)
- JSON API for tests: `http://smscatcher/api/messages` (from inside the docker network)

## Send an SMS to it (Spryng REST API v1)

```shell
curl -X POST http://localhost:1090/v1/messages \
  -H 'Authorization: Bearer dev-api-key' \
  -H 'Content-Type: application/json' \
  -d '{
        "body": "Your verification code is 123456",
        "encoding": "auto",
        "originator": "OpenConext",
        "route": "business",
        "recipients": ["31612345678"]
      }'
```

Responds `201` with the created message resource (including its `id`), or
`422 {"message": ..., "errors": {...}}` on validation errors and
`401 {"message": "Unauthenticated."}` when the Bearer token is missing. Set the
env var `SPRYNG_API_KEY` to require one specific token.

Also implemented: `GET /v1/messages` (with `filters[...]`, `limit`, `page`),
`GET /v1/messages/{id}`, `POST /v1/messages/{id}/cancel`, `GET /v1/balance`,
and the legacy simple API
`GET|POST /api/simple/message?destination=...&sender=...&body=...` (returns
`1` on success, like the real Spryng simple API).

## Pointing Stepup-Gateway at it

The gateway's `SpryngService` uses the `spryng/rest-api-php` SDK, which
hardcodes the base URL `https://rest.spryngsms.com/v1`. To redirect the gateway
to SMSCatcher in devconf, either:

- map `rest.spryngsms.com` to the smscatcher container (e.g. `extra_hosts` in
  `stepup/docker-compose.yml`) and serve TLS with a matching certificate — note
  the dev CA is name-constrained to `.dev.openconext.local`, so this needs a
  gateway-side change, or
- set the Spryng base URL in the gateway to `http://smscatcher/v1`
  (small change in Stepup-Gateway, e.g. making `Spryng::$baseUrl` configurable
  via a parameter/env var), or
- use SMSCatcher directly from tests/scripts with any HTTP client, as above.

## JSON API (for Behat / assertions)

| Endpoint | Description |
| --- | --- |
| `GET /api/messages` (or `/messages`) | all captured messages, newest first |
| `GET /api/messages/{id}` | one message |
| `DELETE /api/messages/{id}` | delete one |
| `DELETE /api/messages` | clear all |
| `GET /api/health` | `{"status": "ok"}` |

Each captured message looks like:

```json
{
  "id": "0b1c2d3e-...",
  "encoding": "auto",
  "body": "Your verification code is 123456",
  "route": "business",
  "originator": "OpenConext",
  "recipients": ["31612345678"],
  "reference": null,
  "credits": 1,
  "status": "send",
  "scheduled_at": null,
  "created_at": "2026-11-04T12:00:00+00:00",
  "updated_at": "2026-11-04T12:00:00+00:00",
  "via": "spryng-rest",
  "links": {"self": "/v1/messages/0b1c2d3e-..."}
}
```

## Configuration (env vars)

| Var | Default | Meaning |
| --- | --- | --- |
| `SPRYNG_API_KEY` | _(unset)_ | if set, `/v1/*` requires exactly this Bearer token |
| `SMSCATCHER_PERSIST_PATH` | `/tmp/smscatcher-messages.json` | JSON file used to persist captured messages |

## Layout

```
smscatcher/
  Dockerfile          # based on the OpenConext php85-apache2 base image
  public/
    index.php         # front controller: Spryng API + UI + JSON API + JSON file store
    .htaccess         # rewrites everything to index.php
```
