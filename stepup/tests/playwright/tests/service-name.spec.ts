import { test, expect, type Page } from '@playwright/test';
import { pushServiceName } from '../lib/middleware';

/**
 * Cross-repo e2e coverage for the "service name during authentication" feature
 * (Stepup-Middleware#589, Stepup-Gateway#624, Stepup-saml-bundle#137,
 * Stepup-gssp-bundle#49, Stepup-gssp-example#141).
 *
 * Flow under test: SP (ssp debug SP) --AuthnRequest w/ mdui:UIInfo--> Gateway
 * (SFO) --proxy AuthnRequest--> GSSP (demogssp) authentication page.
 *
 * Priority rule under test (see REFINEMENT_SERVICE_NAME.md):
 *   Middleware `service_name`, when configured for the SP, always wins over
 *   any mdui:DisplayName sent by the SP in the AuthnRequest.
 *
 * Prerequisites:
 *   - devconf-service-name/stepup environment running (./start-dev-env.sh -d
 *     with gateway/demogssp/middleware pointed at your local checkouts if you
 *     want to test in-progress branches).
 *   - APP_ENV=smoketest in .env (routes the apps to the *_test databases).
 *   - The Behat suite must have been run at least once against this stack
 *     (docker compose exec behat ./vendor/bin/behat --config config/behat.yml)
 *     so the "jane-a-ra" identity with a vetted demo-gssp second factor
 *     exists — that fixture setup lives in the Behat suite's @BeforeSuite
 *     hook, not duplicated here.
 *
 * Run: NODE_TLS_REJECT_UNAUTHORIZED=0 npx playwright test
 */

const SECOND_SP_ENTITY_ID = 'https://ssp.dev.openconext.local/simplesaml/module.php/saml/sp/metadata.php/second-sp';
const VETTED_SUBJECT = 'urn:collab:person:institution-a.example.com:jane-a-ra';

async function startSfoAuthentication(page: Page, mduiDisplayName?: string): Promise<void> {
  await page.goto('/simplesaml/sp.php');
  await page.locator('#idp').selectOption('OpenConext Stepup Gateway - gateway.dev.openconext.local - SFO');
  await page.locator('#sp').selectOption('second-sp');
  await page.locator('#loa').selectOption('2');
  await page.locator('#subject').fill(VETTED_SUBJECT);
  if (mduiDisplayName) {
    await page.locator('#mdui_displayname').fill(mduiDisplayName);
  } else {
    await page.locator('#mdui_displayname').fill('');
  }
  await page.getByRole('button', { name: 'Login' }).first().click();
  await expect(page).toHaveURL('https://demogssp.dev.openconext.local/authentication');
}

test.describe('Service name during authentication', () => {
  test.afterEach(async () => {
    // Leave the shared devconf environment as we found it.
    await pushServiceName(SECOND_SP_ENTITY_ID, null);
  });

  test('shows the AuthnRequest mdui:DisplayName when Middleware has no service_name configured', async ({ page }) => {
    await pushServiceName(SECOND_SP_ENTITY_ID, null);

    await startSfoAuthentication(page, 'Behat Test Service');

    await expect(page.getByText('Behat Test Service')).toBeVisible();
    await page.screenshot({ path: 'screenshots/01-authnrequest-mdui-shown.png', fullPage: true });
  });

  test('Middleware service_name overrides the AuthnRequest mdui:DisplayName', async ({ page }) => {
    await pushServiceName(SECOND_SP_ENTITY_ID, 'Middleware Configured Name');

    await startSfoAuthentication(page, 'Behat Test Service');

    await expect(page.getByText('Middleware Configured Name')).toBeVisible();
    await expect(page.getByText('Behat Test Service')).not.toBeVisible();
    await page.screenshot({ path: 'screenshots/02-middleware-overrides-authnrequest.png', fullPage: true });
  });

  test('renders without error when neither Middleware service_name nor mdui:DisplayName is present', async ({ page }) => {
    await pushServiceName(SECOND_SP_ENTITY_ID, null);

    await startSfoAuthentication(page);

    await expect(page.getByText('Service name')).not.toBeVisible();
    await page.screenshot({ path: 'screenshots/03-no-service-name-no-error.png', fullPage: true });
  });
});
