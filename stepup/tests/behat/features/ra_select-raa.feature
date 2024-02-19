Feature: A RAA manages RA(A)'s on the promotion page
  In order to manage RA(A)'s
  As a RAA
  I must be able to promote and demote identities to RA(A)'s

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given a user "jane-a2" identified by "urn:collab:person:institution-a.example.com:jane-a2" from institution "institution-a.example.com"
    Given a user "joe-d1" identified by "urn:collab:person:institution-d.example.com:joe-d1" from institution "institution-d.example.com"
    And the user "urn:collab:person:institution-a.example.com:jane-a2" has a vetted "yubikey" identified by "00000001"
    And the user "urn:collab:person:institution-d.example.com:joe-d1" has a vetted "yubikey" identified by "00000005"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-d.example.com"
    And institution "institution-d.example.com" can "use_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
    And institution "institution-d.example.com" can "use_ra" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
  Scenario: SRAA user promotes "jane-a2" to be an RAA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the RA promotion page
    Then I change the role of "jane-a2" to become "RAA" for institution "institution-a.example.com"

  Scenario: User "jane-a2" promotes "joe-d1" to be an RA
    Given I am logged in into the ra portal as "jane-a2" with a "yubikey" token
    And I visit the RA promotion page
    Then I change the role of "joe-d1" to become "RA" for institution "institution-a.example.com"

  Scenario: User "jane-a2" demotes "joe-d1" to no longer be an RA
    Given I am logged in into the ra portal as "jane-a2" with a "yubikey" token
    And I visit the RA Management page
    Then I relieve "joe-d1" from "institution-a.example.com" of his "RA" role

  Scenario: SRAA user demotes "jane-a2" to no longer be an RAA
    Given I am logged in into the ra portal as "admin" with a "yubikey" token
    And I visit the RA Management page
    Then I relieve "jane-a2" from "institution-a.example.com" of his "RAA" role
