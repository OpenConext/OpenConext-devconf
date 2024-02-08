Feature: A RAA can export tokens registered in the selfservice portal
  In order to export tokens
  As a RAA
  I must be able to export second factor tokens

  Scenario: RA user can't vet a token from another institution it is not RA for
    Given a user "user-a-ra" identified by "urn:collab:person:institution-a.example.com:user-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000001"
      And a user "jane-a-raa" identified by "urn:collab:person:institution-a.example.com:jane-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000002"
      And a user "joe-a-raa" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000003"
      And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
      And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
      And institution "institution-b.example.com" can "use_raa" from institution "institution-b.example.com"
      And institution "institution-b.example.com" can "select_raa" from institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:user-a-ra" has a vetted "yubikey" with identifier "00000001"
      And the user "urn:collab:person:institution-a.example.com:user-a-ra" has the role "ra" for institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has a vetted "yubikey" with identifier "00000002"
      And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has the role "raa" for institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey" with identifier "00000003"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has the role "ra" for institution "institution-a.example.com"
      And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has the role "raa" for institution "institution-b.example.com"

#  TODO: Scenario: an RA user can not export tokens
#    Given I am logged in into the ra portal as "user-a-ra" with a "yubikey" token
#    When I visit the Tokens page
#    Then I should not see a token export button

  Scenario: an RAA user can export tokens
   Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
    When I visit the Tokens page
     And I click on the token export button
    Then the response should contain "\"Token ID\",Type,Name,Email,Institution,\"Document Number\",Status"
     And the response should contain "00000003,yubikey,joe-a-raa,foo@bar.com,institution-a.example.com,123456,vetted"
     And the response should contain "00000002,yubikey,jane-a-raa,foo@bar.com,institution-a.example.com,123456,vetted"
     And the response should contain "00000001,yubikey,user-a-ra,foo@bar.com,institution-a.example.com,123456,vetted"

  Scenario: a user which is at least RAA for one institution can export tokens
  Given I am logged in into the ra portal as "joe-a-raa" with a "yubikey" token
   When I visit the Tokens page
    And I click on the token export button
   Then the response should contain "\"Token ID\",Type,Name,Email,Institution,\"Document Number\",Status"
    And the response should contain "00000003,yubikey,joe-a-raa,foo@bar.com,institution-a.example.com,123456,vetted"
    And the response should contain "00000002,yubikey,jane-a-raa,foo@bar.com,institution-a.example.com,123456,vetted"
    And the response should contain "00000001,yubikey,user-a-ra,foo@bar.com,institution-a.example.com,123456,vetted"
