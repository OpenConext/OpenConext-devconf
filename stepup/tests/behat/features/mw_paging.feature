Feature: The paging should work for the token audit log
  In order to see a log trace
  As a SRAA
  I must be able to see the next page of the token audit log

    Scenario: A user registers a SMS token in selfservice using RA vetting
        Given a user "jane-a1" identified by "urn:collab:person:institution-a.example.com:jane-a1" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000010"
            And the user "urn:collab:person:institution-a.example.com:jane-a1" has a vetted "yubikey" with identifier "00000010"
            And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
            And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
            And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
            And I am logged in into the ra portal as "admin" with a "yubikey" token
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
            And I visit the RA promotion page
            And I change the role of "jane-a1" to become "RA" for institution "institution-a.example.com"
            And I visit the RA Management page
            And I relieve "jane-a1" from "institution-a.example.com" of his "RA" role
        When I visit the Tokens page
            And I open the audit log for a user of "institution-a.example.com"
            And I click on link "Next"
        Then I should be on page "/second-factors/00000000-0000-4000-a000-000000000010/auditlog?p=2"
            And I should see "Admin"
