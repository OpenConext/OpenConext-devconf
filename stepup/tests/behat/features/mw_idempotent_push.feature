Feature: Duplicate management pushes do not grow the event stream
  In order to keep the event stream lean
  As an operations team
  Repeated identical config pushes must not add new events

  Scenario: Pushing the same whitelist twice does not add events
    Given I authenticate to the Middleware API
    And I record the event stream count for aggregate "125ccee5-d650-437a-a0b0-6bf17c8188fa"
    And I have the payload
      """
      {
        "institutions": [
          "dev.openconext.local",
          "institution-a.example.com",
          "institution-b.example.com",
          "institution-d.example.com",
          "institution-e.example.com",
          "institution-f.example.com",
          "institution-g.example.com",
          "institution-h.example.com",
          "institution-i.example.com",
          "institution-j.example.com",
          "institution-v.example.com"
        ]
      }
      """
    When I request "POST /management/whitelist/replace"
    Then the api response status code should be 200
    And the "status" property should equal "OK"
    And the event stream count for aggregate "125ccee5-d650-437a-a0b0-6bf17c8188fa" should not have increased

  Scenario: Pushing a changed whitelist does add an event
    Given I authenticate to the Middleware API
    And I record the event stream count for aggregate "125ccee5-d650-437a-a0b0-6bf17c8188fa"
    And I have the payload
      """
      {
        "institutions": [
          "dev.openconext.local",
          "institution-a.example.com"
        ]
      }
      """
    When I request "POST /management/whitelist/replace"
    Then the api response status code should be 200
    And the "status" property should equal "OK"
    And I record the event stream count for aggregate "125ccee5-d650-437a-a0b0-6bf17c8188fa"
    And I have the payload
      """
      {
        "institutions": [
          "dev.openconext.local",
          "institution-a.example.com"
        ]
      }
      """
    When I request "POST /management/whitelist/replace"
    Then the api response status code should be 200
    And the event stream count for aggregate "125ccee5-d650-437a-a0b0-6bf17c8188fa" should not have increased

  Scenario: Pushing the same configuration twice does not add events
    Given I authenticate to the Middleware API
    And I have the payload
      """
      {
        "gateway": {
          "identity_providers": [],
          "service_providers": []
        }
      }
      """
    When I request "POST /management/configuration"
    Then the api response status code should be 200
    And I record the event stream count for aggregate "12345678-abcd-4321-abcd-123456789012"
    And I have the payload
      """
      {
        "gateway": {
          "identity_providers": [],
          "service_providers": []
        }
      }
      """
    When I request "POST /management/configuration"
    Then the api response status code should be 200
    And the "status" property should equal "OK"
    And the event stream count for aggregate "12345678-abcd-4321-abcd-123456789012" should not have increased
