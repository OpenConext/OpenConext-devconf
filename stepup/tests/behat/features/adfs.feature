Feature: As an institution that uses ADFS support on the second factor only feature
  In order to do ADFS second factor authentications
  I must be able to successfully authenticate with my second factor tokens

  Scenario: A user logs in using ADFS parameters
    Given a service provider configured for second-factor-only
    When I visit the ADFS service provider
    And I verify the "yubikey" second factor
    Then I am logged on the service provider

  Scenario: A user logs in using ADFS parameters with a gssp token
    Given a user "jane-a-ra" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "demo-gssp" with identifier "gssp-identifier123"
    And a service provider configured for second-factor-only
    When I start an ADFS authentication for "urn:collab:person:institution-a.example.com:jane-a-ra"
    And I verify the "demo-gssp" second factor
    Then I am logged on the service provider

  Scenario: A user cancels ADFS authn with a gssp token
    And a service provider configured for second-factor-only
    When I start an ADFS authentication for "urn:collab:person:institution-a.example.com:jane-a-ra"
    And I cancel the "demo-gssp" second factor authentication
    Then I see an ADFS error at the service provider

  Scenario: A user cancels ADFS authn with a yubikey token
    Given a service provider configured for second-factor-only
    When I visit the ADFS service provider
    And I cancel the "yubikey" second factor authentication
    Then I see an ADFS error at the service provider

