Feature: A RAA manages ra candidates in the ra environment (see: https://www.pivotaltracker.com/story/show/171703175)
  In order to promote candidates
  As a RAA
  I must be able to promote and demote identities were I'm allowed to through the authorization config

  Scenario: Provision an institution and a user to promote later on by an authorized institution
    Given institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"

      And institution "institution-d.example.com" can "select_raa" from institution "institution-a.example.com"

      And a user "joe-a-raa institution-a" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com" with UUID "3af4eba5-8d1b-4da4-a6ba-c730356f36e1"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey" identified by "00000002"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has the role "raa" for institution "institution-a.example.com"
      And a user "jane-a2 institution-a" identified by "urn:collab:person:institution-a.example.com:jane-a2" from institution "institution-a.example.com" with UUID "3af4eba5-8d1b-4da4-a6ba-c730356f36e2"
      And the user "urn:collab:person:institution-a.example.com:jane-a2" has a vetted "yubikey" identified by "00000003"

      And a user "jane-d-raa institution-d.nl" identified by "urn:collab:person:institution-d.example.com:jane-d-raa" from institution "institution-d.example.com" with UUID "3af4eba5-8d1b-4da4-a6ba-c730356f36e3"
      And the user "urn:collab:person:institution-d.example.com:jane-d-raa" has a vetted "yubikey" identified by "00000004"

  Scenario: RAA from institution a should not see an RA(A) candidate from institution d
    Given I am logged in into the ra portal as "joe-a-raa" with a "yubikey" token
    When I visit the RA promotion page
    Then I should see the following candidates for "institution-a.example.com":
      | name                    | institution               |
      | jane-a2 institution-a   | institution-a.example.com |
      | joe-a-raa institution-a | institution-a.example.com |
