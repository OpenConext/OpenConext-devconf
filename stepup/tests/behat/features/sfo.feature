Feature: A user authenticates with a service provider configured for second-factor-only
  In order to login on a service provider
  As a user
  I must verify the second factor without authenticating with an identity provider

  Scenario: A user logs in using SFO using a GSSP token
    Given a service provider configured for second-factor-only
    And a user "jane-a-ra" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "demo-gssp" with identifier "gssp-identifier123"
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a-ra"
    And I verify the "demo-gssp" second factor
    Then I am logged on the service provider

  Scenario: A user cancels SFO authn with a gssp token
    And a service provider configured for second-factor-only
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a-ra"
    And I cancel the "demo-gssp" second factor authentication
    Then I see an error at the service provider

  Scenario: Admin logs in using SFO using a Yubikey token
    Given a service provider configured for second-factor-only
    When I start an SFO authentication for "urn:collab:person:dev.openconext.local:admin"
    And I verify the "yubikey" second factor
    Then I am logged on the service provider

  Scenario: Admin user cancels SFO authn with a Yubikey token
    And a service provider configured for second-factor-only
    When I start an SFO authentication for "urn:collab:person:dev.openconext.local:admin"
    And I cancel the "yubikey" second factor authentication
    Then I see an error at the service provider
