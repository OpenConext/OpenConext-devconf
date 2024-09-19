Feature: A RAA can only manage R RA(A)'s on the promotion page
  In order to manage RA(A)'s
  As a user
  I must see a sane error  message when I login to RA but I'm not accredited as RA

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given a user "joe-a-raa" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey" with identifier "00000004"

  Scenario: User "joe-a-raa"  tries to login while not accredited as RAA should be informed
    Given I try to login into the ra portal as "joe-a-raa" with a "yubikey" token
    Then I should see "Error - Access denied"
     And I should see "Authentication was successful, but you are not authorised to use the RA management portal"

  Scenario: User "jane-d4" tries to login with no 2FA token available
    Given a user "jane-d4" identified by "urn:collab:person:institution-d.example.com:jane-d4" from institution "institution-d.example.com"
    # The identity does not have a second factor token and can by no means log in to RA
    And I try to login into the ra portal as "jane-d4"
    And I press "Submit"
    Then I should see "Error - Not authorised to sign in"
    And I should see "Error code"
    And I should see "11430"

  Scenario: User "joe-a3" tries to login while no acceptable 2FA token is available
    Given a user "joe-a3" identified by "urn:collab:person:institution-a.example.com:joe-a3" from institution "institution-a.example.com"
    # The token is not suitable to log in to RA, and the user is not acreditted the RA role.
    And the user "urn:collab:person:institution-a.example.com:joe-a3" has a vetted "sms" with identifier "+31 (0) 687654321"
    And I try to login into the ra portal as "joe-a3"
    And I press "Submit"
    Then I should see "Error - Not authorised to sign in"
    And I should see "Error code"
    And I should see "11430"

  Scenario: User "admin" cancels the second factor authentication
    Given I try to login into the ra portal as "admin"
    # Cancel the yubikey second factor authentication
    Then I press "Cancel"
    # Pass throug gateway
    And I press "Submit"
    Then I should see "Error - Sign in"
    And I should see "Error code"
    And I should see "32592"
