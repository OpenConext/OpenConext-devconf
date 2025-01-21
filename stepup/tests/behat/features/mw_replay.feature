Feature: A replay is performed on Middleware
  In order to replay an event stream
  On the command line
  I expect the last event to be reflected in the data set

  Scenario: After a replay is performed I would expect the last event reflected in the data set
    Given a replay of eventstream is performed
    Given I authenticate with user "ra" and password "secret"
      And I request "GET /identity?institution=institution-b.example.com&NameID=urn:collab:person:institution-b.example.com:joe-b5"
    Then the api response status code should be 200
      And the "items" property should contain 1 items
