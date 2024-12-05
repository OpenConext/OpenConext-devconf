Feature: A user manages his tokens in the SelfService portal
  In order to use a second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: A user registers a SMS token in selfservice using RA vetting
    Given I am logged in into the selfservice portal as "joe-a1"
    When I register a new "SMS" token
    And I verify my e-mail address and choose the "RA vetting" vetting type
    And I vet my "SMS" second factor at the information desk

  Scenario: A user registers a Yubikey token in selfservice using RA vetting
    Given I am logged in into the selfservice portal as "joe-a2"
    When I register a new "Yubikey" token
    And I verify my e-mail address and choose the "RA vetting" vetting type
    And I vet my "Yubikey" second factor at the information desk

  Scenario: A user registers a Demo GSSP token in selfservice using RA vetting
    Given I am logged in into the selfservice portal as "joe-a3"
    When I register a new "Demo GSSP" token
    And I verify my e-mail address and choose the "RA vetting" vetting type
    And I vet my "Demo GSSP" second factor at the information desk

  Scenario: A user registers a SMS token in selfservice using RA vetting without mail verification
    Given I am logged in into the selfservice portal as "joe-b1"
    When I register a new "Yubikey" token
    And I choose the "RA vetting" vetting type
    And I vet my "Yubikey" second factor at the information desk

  Scenario: After token registration, the token can be viewed on the token overview page
    Given I am logged in into the selfservice portal as "joe-a1"
    Then I visit the "overview" page in the selfservice portal
    Then I should see "The following tokens are registered for your account."
    And I should see "SMS"
    And I should see "Test a token"

Scenario: A user can validate an email address when not logged into selfservice
    Given I am logged in into the selfservice portal as "jane-a2"
    And I register a new "Yubikey" token
    When  I log out of the selfservice portal
    Then I verify my e-mail address
    And  pass through GW
    And I choose the "RA vetting" vetting type

