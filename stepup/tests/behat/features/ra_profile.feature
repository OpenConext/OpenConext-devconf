Feature: A RA(A) can view profile information

  Scenario: Jane Toppan is RAA at Institution A and Joe is RA at Insittution A
    Given I have the payload
        """
        {
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2,
                "select_raa": [
                    "institution-a.example.com"
                ]
            },
            "institution-f.example.com": {
                "use_ra_locations": false,
                "show_raa_contact_information": false,
                "verify_email": false,
                "allowed_second_factors": ["sms"],
                "number_of_tokens_per_identity": 1,
                "select_raa": []
            }
        }
        """
    And I authenticate to the Middleware API
    And I request "POST /management/institution-configuration"
    And institution "institution-a.example.com" can "use_ra" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "use_raa" from institution "institution-a.example.com"
    And institution "institution-a.example.com" can "select_raa" from institution "institution-a.example.com"
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-A000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has a vetted "yubikey" identified by "00000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-ra" has the role "raa" for institution "institution-a.example.com"
    And a user "Joe Satriani" identified by "urn:collab:person:institution-a.example.com:joe-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-A000-000000000002"
    And the user "urn:collab:person:institution-a.example.com:joe-a-ra" has a vetted "yubikey" identified by "00000002"
    And the user "urn:collab:person:institution-a.example.com:joe-a-ra" has the role "ra" for institution "institution-a.example.com"

  Scenario: RAA user for one institution sees the authorization for that institution
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    When I visit the "profile" page in the RA environment
    Then I should see the following profile:
      | Label             | Value                                                 |
      | Name              | Jane Toppan                                           |
      | Username (NameID) | urn:collab:person:institution-a.example.com:jane-a-ra |
      | E-mail            | foo@bar.com                                           |
      | Preferred locale  | en_GB                                                 |
      | Authorizations    | RAA @ institution-a.example.com                       |

  Scenario: RAA user for multiple institutions sees the implicit authorizations
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    And institution "institution-b.example.com" can "use_ra" from institution "institution-a.example.com"
    When I visit the "profile" page in the RA environment
    Then I should see the following profile:
      | Label             | Value                                                          |
      | Name              | Jane Toppan                                                    |
      | Username (NameID) | urn:collab:person:institution-a.example.com:jane-a-ra          |
      | E-mail            | foo@bar.com                                                    |
      | Preferred locale  | en_GB                                                          |
      | Authorizations    | RAA @ institution-a.example.com RA @ institution-b.example.com |

  Scenario: RAA user is accredited correct RAA role at institution B
    Given I am logged in into the ra portal as "jane-a-ra" with a "yubikey" token
    And institution "institution-b.example.com" can "use_raa" from institution "institution-a.example.com"
    When I visit the "profile" page in the RA environment
    Then I should see the following profile:
      | Label             | Value                                                           |
      | Name              | Jane Toppan                                                     |
      | Username (NameID) | urn:collab:person:institution-a.example.com:jane-a-ra           |
      | E-mail            | foo@bar.com                                                     |
      | Preferred locale  | en_GB                                                           |
      | Authorizations    | RAA @ institution-a.example.com RAA @ institution-b.example.com |

  Scenario: RA user for multiple institutions sees the implicit authorizations
    Given I am logged in into the ra portal as "joe-a-ra" with a "yubikey" token
    And institution "institution-b.example.com" can "use_ra" from institution "institution-a.example.com"
    When I visit the "profile" page in the RA environment
    Then I should see the following profile:
      | Label             | Value                                                         |
      | Name              | Joe Satriani                                                  |
      | Username (NameID) | urn:collab:person:institution-a.example.com:joe-a-ra          |
      | E-mail            | foo@bar.com                                                   |
      | Preferred locale  | en_GB                                                         |
      | Authorizations    | RA @ institution-a.example.com RA @ institution-b.example.com |

  Scenario: RA user is not accredited RAA role at institution B
    Given I am logged in into the ra portal as "joe-a-ra" with a "yubikey" token
    And institution "institution-b.example.com" can "use_raa" from institution "institution-a.example.com"
    When I visit the "profile" page in the RA environment
    Then I should see the following profile:
      | Label             | Value                                                |
      | Name              | Joe Satriani                                         |
      | Username (NameID) | urn:collab:person:institution-a.example.com:joe-a-ra |
      | E-mail            | foo@bar.com                                          |
      | Preferred locale  | en_GB                                                |
      | Authorizations    | RA @ institution-a.example.com                       |
