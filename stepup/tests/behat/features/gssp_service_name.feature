# Tagged SKIP until both of these are merged and released in their test images:
#   - Stepup-Gateway PR #624 (enable_service_name_from_saml_authnrequest)
#   - OpenConext-devssp PR adding the mdui_displayname field to sp.php
# Until then, run locally with:
#   ./start-dev-env.sh gateway:<Stepup-Gateway checkout> demogssp:<Stepup-gssp-example checkout>
#   docker compose exec behat ./vendor/bin/behat --config config/behat.yml features/gssp_service_name.feature
@SKIP
Feature: The GSSP shows the name of the service the user is authenticating for
  In order to know which service I am authenticating for
  As a user
  I want the GSSP authentication page to show the service name from the AuthnRequest

  # Covers the cross-repo flow of the mdui:UIInfo service name:
  # the SP sends an AuthnRequest with an mdui:UIInfo/mdui:DisplayName extension,
  # the Stepup-Gateway (feature flag enable_service_name_from_saml_authnrequest)
  # reads it and forwards it in the proxy AuthnRequest to the GSSP, where the
  # GSSP (Stepup-gssp-example via Stepup-gssp-bundle and Stepup-saml-bundle)
  # displays it on the authentication page.
  Scenario: Service name from the AuthnRequest mdui:UIInfo is shown on the GSSP authentication page
    Given a service provider configured for second-factor-only
    And a user "jane-a-ra" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "demo-gssp" with identifier "gssp-identifier123"
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a-ra" with service name "Behat Test Service"
    Then I see service name "Behat Test Service" on the GSSP authentication page
    When I verify the "demo-gssp" second factor
    Then I am logged on the service provider

  # Reuses the identity vetted in the previous scenario, like sfo.feature does.
  Scenario: No service name is shown when the AuthnRequest carries no mdui:UIInfo
    Given a service provider configured for second-factor-only
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a-ra"
    Then I should not see "Behat Test Service"
    When I verify the "demo-gssp" second factor
    Then I am logged on the service provider
