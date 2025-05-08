Feature: A user authenticates with a service provider configured for second-factor-only
  In order to login on a service provider
  As a user
  I must verify the second factor without authenticating with an identity provider

  Scenario: A user logs in using SFO using a GSSP token
    Given a service provider configured for second-factor-only with loa 1.5
    And a user "jane-a1" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
  Given I receive the following attributes for "jane-a1" from the IdP:
      | name                                                    | value                                          |
      | urn:mace:dir:attribute-def:mail                         | jane-a1@institution-a.example.com              |
      | urn:mace:terena.org:attribute-def:schacHomeOrganization | institution-a.example.com                      |
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a1"
    And I verify the azuremfa gssp second factor with email address "jane-a1@institution-a.example.com"
    Then I am logged on the service provider

  Scenario: A user cancels SFO authn with a gssp token
    And a service provider configured for second-factor-only
    When I start an SFO authentication for "urn:collab:person:institution-a.example.com:jane-a1"
    And I cancel the "azuremfa-gssp" second factor authentication
    Then I see an error at the service provider
