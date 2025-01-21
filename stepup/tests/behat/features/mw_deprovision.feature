Feature: A user can be deprovisioned from Middleware
  In order to deprovision a user for middleware
  On the command line
  I expect this to be reflected in the data set

  Scenario: After a replay is performed I would expect the last event reflected in the data set
    Given a replay of deprovision is performed
    Given I authenticate with user "lifecycle" and password "secret"
      And I request "DELETE /deprovision/urn:collab:person:institution-a.example.com:joe-a-raa"
    Then the api response status code should be 200
    And the database should not contain
    | name              | value                         |
    | email             | joe-a-raa@institution-a.nl    |
    | common_name       | Joe RAA                       |
    | document_number   | 467890                        |
