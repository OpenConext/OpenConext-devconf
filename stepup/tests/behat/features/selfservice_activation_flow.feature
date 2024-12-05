Feature: A user manages his tokens in the SelfService portal
  In order to use a second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: A user registers a Yubikey token in selfservice using RA vetting preference
  Given I receive no additional attributes for "joe-a4" from the IdP
    And I log into the selfservice portal as "joe-a4" with activation preference "ra"
    When I register a new "Yubikey" token
    And I verify my e-mail address
    And I visit the "overview" page in the selfservice portal
    And I activate my token
    Then I should see "Activation code"

  Scenario: A user registers a Yubikey token in selfservice using self vetting preference
  Given I receive no additional attributes for "joe-a5" from the IdP
    And I log into the selfservice portal as "joe-a5" with activation preference "self"
    When I register a new "Yubikey" token
    And I verify my e-mail address
    And I visit the "overview" page in the selfservice portal
    And I activate my token
    Then I should see "Add recovery method"

  Scenario: A user registers a Yubikey token in selfservice using RA vetting preference set through eduPersonEntitlement attribute
      Given I receive the following attributes for "jane-a4" from the IdP:
        | name                                            | value                                          |
        | urn:mace:dir:attribute-def:eduPersonEntitlement | urn:mace:surf.nl:surfsecureid:activation:ra    |
    And I am logged in into the selfservice portal as "jane-a4"
    When I register a new "Yubikey" token
    And I verify my e-mail address
    And I visit the "overview" page in the selfservice portal
    And I activate my token
    Then I should see "Activation code"

  Scenario: A user registers a Yubikey token in selfservice using self vetting preference set through eduPersonEntitlement attribute
    Given I receive the following attributes for "jane-a5" from the IdP:
      | name                                            | value                                           |
      | urn:mace:dir:attribute-def:eduPersonEntitlement | urn:mace:surf.nl:surfsecureid:activation:self   |
    And I am logged in into the selfservice portal as "jane-a5"
    When I register a new "Yubikey" token
    And I verify my e-mail address
    And I visit the "overview" page in the selfservice portal
    And I activate my token
    Then I should see "Add recovery method"
