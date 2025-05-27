Feature: A user authenticates with a service provider configured for second-factor-only
  In order to login on a service provider
  As a user
  I must verify the second factor without authenticating with an identity provider

  Scenario: A user logs in using SFO using a GSSP token
    Given a service provider configured for second-factor-only with loa 1.5
    And a user "jane-a1" identified by "urn:collab:person:institution-a.example.com:jane-a1" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a1" with GSSP extension subject "jane-a1@institution-a.example.com" and institution "institution-a.example.com"
    And I verify the azuremfa gssp second factor with email address "jane-a1@institution-a.example.com"
    Then I am logged on the service provider

  Scenario: A user cancels SFO authn with a gssp token
    Given a service provider configured for second-factor-only with loa 1.5
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a1" with GSSP extension subject "jane-a1@institution-a.example.com" and institution "institution-a.example.com"
      And I cancel the "azuremfa-gssp" second factor authentication
    Then I see an error at the service provider
