import { defineConfig } from '@playwright/test';

// Requires the stepup devconf environment running with the `smoketest` .env profile
// (see ../../README.md) so the app containers use *_test databases and the
// hosts file entries for *.dev.openconext.local resolve to 127.0.0.1.
export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  fullyParallel: false,
  reporter: 'list',
  use: {
    ignoreHTTPSErrors: true,
    baseURL: 'https://ssp.dev.openconext.local',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
  },
});
