Feature: A RAA can view the institution configuration

  Scenario: Jane Toppan is RAA at Institution A
    Given I have the payload
        """
        {
            "institution-a.example.com": {
                "use_ra_locations": true,
                "show_raa_contact_information": true,
                "verify_email": true,
                "self_vet": true,
                "sso_on_2fa": true,
                "sso_registration_bypass": true,
                "allow_self_asserted_tokens": true,
                "allowed_second_factors": [],
                "number_of_tokens_per_identity": 2
            },
            "institution-d.example.com": {
                "use_ra_locations": false,
                "show_raa_contact_information": false,
                "verify_email": false,
                "allowed_second_factors": ["sms"],
                "number_of_tokens_per_identity": 1,
                "use_raa": [
                    "institution-a.example.com"
                ]
            }
        }
        """
    And I authenticate to the Middleware API
    And I request "POST /management/institution-configuration"
    And a user "Jane Toppan" identified by "urn:collab:person:institution-a.example.com:jane-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has a vetted "yubikey" with identifier "00000001"
    And the user "urn:collab:person:institution-a.example.com:jane-a-raa" has the role "raa" for institution "institution-a.example.com"

  Scenario: RAA user for institution A sees the institution-configuration for that institution
    Given I am logged in into the ra portal as "jane-a-raa" with a "yubikey" token
     When I visit the "institution-configuration" page in the RA environment
     Then I should see "Configuration of institution-a.example.com"
      And The institution configuration should be:
        | Label                                                                                      | Value                            |
        | Use RA locations enabled?                                                                  | Yes                              |
        | Show RAA contact information?                                                              | Yes                              |
        | E-mail verification enabled?                                                               | Yes                              |
        | Single sign on on second factor authentications?                                           | Yes                               |
        | GSSP Fallback enabled?                                                                     | Yes                               |
        | Token activation using an activated token                                                  | Allowed                      |
        | Activate a token without the service desk or an activated token                            | Allowed                      |
        | Allowed second factor tokens                                                               | All enabled tokens are available |
        | Number of tokens per identity                                                              | 2                                |
        | From which institution(s) can users be assigned the RA(A) role for this institution?       | institution-a.example.com        |
        | From which institution(s) are the RAs an RA for this institution?                          | institution-a.example.com        |
        | From which institution(s) are the RAAs an RAA for this institution?                        | institution-a.example.com        |
     Then I switch to institution "institution-d.example.com" with institution switcher
     Then I should see "Configuration of institution-d.example.com"
      And The institution configuration should be:
        | Label                                                                                      | Value                            |
        | Use RA locations enabled?                                                                  | No                               |
        | Show RAA contact information?                                                              | No                               |
        | E-mail verification enabled?                                                               | No                               |
        | Single sign on on second factor authentications?                                           | No                               |
        | GSSP Fallback enabled?                                                                     | No                               |
        | Token activation using an activated token                                                  | Not allowed                      |
        | Activate a token without the service desk or an activated token                            | Not allowed                      |
        | Allowed second factor tokens                                                               | sms                              |
        | Number of tokens per identity                                                              | 1                                |
        | From which institution(s) can users be assigned the RA(A) role for this institution?       | institution-d.example.com        |
        | From which institution(s) are the RAs an RA for this institution?                          | institution-d.example.com        |
        | From which institution(s) are the RAAs an RAA for this institution?                        | institution-a.example.com        |
