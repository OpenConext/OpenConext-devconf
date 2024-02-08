Feature: A user manages his tokens in the SelfService portal
  In order to SAT register a second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: A user registers a SMS token in selfservice using SAT
    Given I am logged in into the selfservice portal as "user-a1"
    When I register a new "SMS" token
    And I verify my e-mail address and choose the "Self Asserted Token registration" vetting type
    And I vet my "SMS" second factor in selfservice
    And "1" recovery tokens are activated

  Scenario: A user registers a Yubikey token in selfservice using SAT
    Given I am logged in into the selfservice portal as "user-a2"
    When I register a new "Yubikey" token
    And I verify my e-mail address and choose the "Self Asserted Token registration" vetting type
    And I vet my "Yubikey" second factor in selfservice
    And "1" recovery tokens are activated

  Scenario: A user registers a Demo GSSP token in selfservice using SAT
    Given I am logged in into the selfservice portal as "user-a3"
    When I register a new "Demo GSSP" token
    And I verify my e-mail address and choose the "Self Asserted Token registration" vetting type
    And I vet my "Demo GSSP" second factor in selfservice
    And "1" recovery tokens are activated

  Scenario: A user can register an additional recovery token
    Given I am logged in into the selfservice portal as "user-a4"
    When I register a new "Yubikey" token
    And I verify my e-mail address and choose the "Self Asserted Token registration" vetting type
    And I vet my "Yubikey" second factor in selfservice
    Then I can add an "SMS" recovery token using "Yubikey"
    And "2" recovery tokens are activated
