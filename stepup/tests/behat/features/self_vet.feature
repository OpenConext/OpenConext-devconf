Feature: A user manages his tokens in the selfservice portal
  In order to use a self vetted second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: Setup of the institution configuration and test users
    Given I have the payload
        """
        {
            "dev.openconext.local": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": false,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 3
            },
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": true,
                "allow_self_asserted_tokens": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 3
            }
        }
        """
    And I authenticate to the Middleware API
    And I request "POST /management/institution-configuration"

  Scenario: A user self vets a token in selfservice
    Given a user "joe-a2" identified by "urn:collab:person:institution-a.example.com:joe-a2" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000001"
      And the user "urn:collab:person:institution-a.example.com:joe-a2" has a vetted "yubikey" with identifier "00000001"
     When I am logged in into the selfservice portal as "joe-a2"
      And I register a new "SMS" token
      And I verify my e-mail address and choose the "Self vetting" vetting type
      And I visit the "overview" page in the selfservice portal
    Then I should see "The following tokens are registered for your account."
      And I should see "SMS"
      And I should see "Yubikey"

    Scenario: A user can self vet a token with a lower LOA
      Given a user "joe-a2" identified by "urn:collab:person:institution-a.example.com:joe-a3" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000002"
        And the user "urn:collab:person:institution-a.example.com:joe-a3" has a vetted "sms" with identifier "+31 (0) 612345678"
      When I am logged in into the selfservice portal as "joe-a3"
        And I register a new "Yubikey" token
        And I verify my e-mail address
        And I visit the "overview" page in the selfservice portal
        And I activate my token
        Then I should see "Activation code"

    Scenario: A user can self vet a token with the same LOA
      Given a user "joe-a4" identified by "urn:collab:person:institution-a.example.com:joe-a4" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000003"
        And the user "urn:collab:person:institution-a.example.com:joe-a4" has a vetted "demo-gssp" with identifier "gssp-identifier123"
      When I am logged in into the selfservice portal as "joe-a4"
        And I register a new "Yubikey" token
        And I verify my e-mail address and choose the "Self vetting" vetting type
        And I visit the "overview" page in the selfservice portal
      Then I should see "The following tokens are registered for your account."
        And I should see "Demo GSSP"
        And I should see "Yubikey"


    Scenario: A user can self vet a token after registering a token using SAT
      Given I am logged in into the selfservice portal as "joe-a5"
        And I register a new "Demo GSSP" token
        And I verify my e-mail address and choose the "Self Asserted Token registration" vetting type
        And I vet my "Demo GSSP" second factor in selfservice
      When I receive the following attributes for "joe-a5" from the IdP:
            | name                                            | value                                            |
            | urn:mace:dir:attribute-def:eduPersonEntitlement | urn:mace:surf.nl:surfsecureid:activation:self    |
        And I log in again into selfservice
        And I register a new "Yubikey" token
        And I verify my e-mail address and choose the "Self vetting" vetting type
        And I visit the "overview" page in the selfservice portal
      Then I should see "The following tokens are registered for your account."
        And I should see "Demo GSSP"
        And I should see "Yubikey"
