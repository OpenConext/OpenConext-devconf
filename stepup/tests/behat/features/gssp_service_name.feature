# Tagged SKIP until Stepup-Gateway PR #624 (append_service_name_to_authnrequest) is merged
# and released in the test image. (OpenConext-devssp's mdui_displayname field already merged
# and is in the stock devssp image, so no local sp.php override is needed anymore.)
# Until then, run locally with:
#   ./start-dev-env.sh gateway:<Stepup-Gateway checkout> demogssp:<Stepup-gssp-example checkout>
#   docker compose exec behat ./vendor/bin/behat --config config/behat.yml --tags='~@wip' features/gssp_service_name.feature
@SKIP
Feature: The GSSP shows the name of the service the user is authenticating for
  In order to know which service I am authenticating for
  As a user
  I want the GSSP authentication page to show the service name from the AuthnRequest

  # Covers the cross-repo flow of the mdui:UIInfo service name:
  # the SP sends an AuthnRequest with an mdui:UIInfo/mdui:DisplayName extension,
  # the Stepup-Gateway (feature flag append_service_name_to_authnrequest)
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

  # Gateway has three independent LoginService::singleSignOn implementations that each
  # read the mdui:UIInfo extension behind the same feature flag: GatewayBundle (plain
  # SSO, exercised here), SecondFactorOnlyBundle, and SamlStepupProviderBundle (both
  # exercised by the SFO scenarios above). Without this scenario, a regression in the
  # SSO copy specifically would go undetected even with the SFO scenarios passing.
  Scenario: Service name from the AuthnRequest mdui:UIInfo is shown on the GSSP authentication page via the plain SSO flow
    Given a service provider configured for single-signon
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a2" from institution "institution-a.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a2" has a vetted "demo-gssp" with identifier "gssp-identifier-sso1"
    When I visit the service provider with service name "SSO Flow Service Name"
    And I authenticate as "jane-a2" with the identity provider
    Then I see service name "SSO Flow Service Name" on the GSSP authentication page
    When I verify the "demo-gssp" second factor
    Then I am logged on the service provider
