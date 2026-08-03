# Service name e2e tests (Playwright)

Cross-repo browser test for the "show service name during authentication" feature:
Stepup-Middleware#589, Stepup-Gateway#624, Stepup-saml-bundle#137,
Stepup-gssp-bundle#49, Stepup-gssp-example#141.

## Prerequisites

1. Start the devconf stepup environment (see `../../README.md`), pointing
   `middleware` / `gateway` / `demogssp` at your local checkouts if you're
   testing branches that aren't in the `test` images yet:

   ```bash
   cd ../..
   ./start-dev-env.sh -d \
     middleware:/path/to/Stepup-Middleware \
     gateway:/path/to/Stepup-Gateway \
     demogssp:/path/to/Stepup-gssp-example
   ```

2. `.env` must have `APP_ENV=smoketest` (routes the apps to `*_test` DBs).

3. Run the Behat suite at least once against this stack so the `jane-a-ra`
   identity (vetted `demo-gssp` second factor) exists — this test reuses
   that fixture data rather than duplicating the bootstrap:

   ```bash
   docker compose exec behat ./vendor/bin/behat --config config/behat.yml \
     --tags='~@wip' features/gssp_service_name.feature
   ```

   Alternatively, skip the Behat dependency entirely and seed the same
   `jane-a-ra` identity directly via Middleware's command API:

   ```bash
   cd ../.. && ./seed-test-identity.sh jane-a-ra institution-a.example.com
   ```

4. `append_service_name_to_authnrequest` defaults to `false`
   (`Stepup-Gateway/config/openconext/parameters.yaml.dist`) and devconf does
   not override it, so it must be enabled manually against the running
   container, e.g.:

   ```bash
   docker compose exec gateway sed -i \
     's/append_service_name_to_authnrequest: false/append_service_name_to_authnrequest: true/' \
     config/openconext/parameters.yaml
   ```

## Install & run

```bash
npm install
npx playwright install chromium   # first time only
NODE_TLS_REJECT_UNAUTHORIZED=0 npx playwright test
```

`NODE_TLS_REJECT_UNAUTHORIZED=0` is needed because the devconf stack uses a
self-signed cert and `lib/middleware.ts` pushes config over `fetch()`
directly (not through Playwright's browser context, which is configured with
`ignoreHTTPSErrors` separately).

## What it does

Each test pushes a config change to Middleware for the `second-sp` SP entity
(`lib/middleware.ts`), then drives the SP debug page
(`https://ssp.dev.openconext.local/simplesaml/sp.php`) through an SFO login
to `demogssp`, asserting on what service name is shown:

- No Middleware `service_name` → the SP's own `mdui:DisplayName` is shown.
- Middleware `service_name` set → it wins, regardless of what the SP sends.
- Neither present → no service name section renders, no error.

Each test resets `second-sp`'s `service_name` back to unset in `afterEach`,
so the shared environment is left as found.
