Feature: A (S)RA(A) user reads identities of StepUp users in the middleware API
  In order to list identities
  As a (S)RA(A) user
  I must be able to read from the middleware API

  Scenario: Provision the following users:
    Given a user "jane-a1" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000001"
    And a user "joe-a1" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000002"
    And a user "jill-a1" identified by "urn:collab:person:institution-a.example.com:jane-a-ra" from institution "institution-a.example.com" with UUID "00000000-0000-4000-8000-000000000003"

  Scenario: A (S)RA(A) user reads identities without additional authorization context
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-a.example.com"
    Then the api response status code should be 200
    And the "items" property should contain 3 items

  Scenario: A (S)RA(A) user reads identities of a non existent institution
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-x.example.com"
    Then the api response status code should be 200
    And the "items" property should be an empty array

  Scenario: The admin SRAA user reads identities with authorization context
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-a.example.com&actorId=e9ab38c3-84a8-47e6-b371-4da5c303669a&actorInstitution=dev.openconext.local"
    Then the api response status code should be 200
    And the "items" property should contain 3 items

  Scenario: The admin SRAA user reads identities with authorization context of a non existent institution
    Given I authenticate with user "ra" and password "secret"
    When I request "GET /identity?institution=institution-x.example.com&actorId=e9ab38c3-84a8-47e6-b371-4da5c303669a&actorInstitution=dev.openconext.local"
    Then the api response status code should be 200
    And the "items" property should be an empty array

  Scenario: A very long NameID is not permitted and should not exceed the pre-configured database length for the field
    Given a user "Longjohn" identified by "urn:collab:person:institution-a.example.com:thisuserhasawaytolongusernamethatexceeds255characters_thisuserhasawaytolongusernamethatexceeds255charactersthisuserhasawaytolongusernamethatexceeds255characters_thisuserhasawaytolongusernamethatexceeds255charactersthisuserhasawaytolongusernamethatexceeds255characters_thisuserhasawaytolongusernamethatexceeds255characters" from institution "institution-a.example.com" and fail with "maximum length for nameId exceeds configured length of 255"
