import fs from 'node:fs';
import path from 'node:path';

const MIDDLEWARE_CONFIG_URL = 'https://middleware.dev.openconext.local/management/configuration';
const MIDDLEWARE_CONFIG_PATH = path.resolve(__dirname, '../../../middleware/middleware-config.json');
const MANAGEMENT_USER = 'management';
const MANAGEMENT_PASSWORD = 'secret';

// service_name is a locale => name map (e.g. { en_GB: "Name" }), per
// ServiceProviderConfigurationValidator / SamlEntity::fromConfiguration on the
// Middleware and Gateway side. A bare string is silently coerced to `[]` by
// `is_array($serviceName) ? $serviceName : []`, so it is never actually applied.
type ServiceProvider = { entity_id: string; service_name?: Record<string, string> | null; [key: string]: unknown };
type MiddlewareConfig = { gateway: { service_providers: ServiceProvider[]; [key: string]: unknown }; [key: string]: unknown };

function loadBaseConfig(): MiddlewareConfig {
  const raw = fs.readFileSync(MIDDLEWARE_CONFIG_PATH, 'utf-8');
  return JSON.parse(raw) as MiddlewareConfig;
}

/**
 * Pushes the devconf baseline middleware-config.json, optionally overriding
 * `service_name` on one SP entity. Pass `serviceName: null` to push the
 * baseline unmodified (no service_name key on that entity), or a plain string
 * to set it for locale "en_GB" (Gateway's default_locale in this environment).
 */
export async function pushServiceName(entityId: string, serviceName: string | null): Promise<void> {
  const config = loadBaseConfig();
  const sp = config.gateway.service_providers.find((s) => s.entity_id === entityId);
  if (!sp) {
    throw new Error(`No service provider with entity_id "${entityId}" found in ${MIDDLEWARE_CONFIG_PATH}`);
  }
  if (serviceName === null) {
    delete sp.service_name;
  } else {
    sp.service_name = { en_GB: serviceName };
  }

  const auth = Buffer.from(`${MANAGEMENT_USER}:${MANAGEMENT_PASSWORD}`).toString('base64');
  const response = await fetch(MIDDLEWARE_CONFIG_URL, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: `Basic ${auth}`,
    },
    body: JSON.stringify(config),
    // devconf uses a self-signed cert; Node's fetch needs this at the process level,
    // see NODE_TLS_REJECT_UNAUTHORIZED=0 in the npm script / CI invocation.
  });

  if (!response.ok) {
    throw new Error(`Middleware config push failed: HTTP ${response.status} ${await response.text()}`);
  }
  const body = (await response.json()) as { status?: string };
  if (body.status !== 'OK') {
    throw new Error(`Middleware config push did not return status OK: ${JSON.stringify(body)}`);
  }
}
