Feature: Login to PDS for EZProxy from off campus
  In order to use authorized resources
  As an off campus researcher
  I would like to be directed to login through EZProxy.

  Background:
    Given I am off campus

  Scenario: Logging into EZProxy as an NYU student
    Given I am on "https://dev.arch.library.nyu.edu/databases/proxy/NYU04564"
    And I am prompted with the login screen
    When I login as an NYU student
    Then I should be redirected to "ebscohost.com.ezproxybeta.library.nyu.edu"

  Scenario: Logging into EZProxy as Cooper Union faculty
    Given I am on "https://dev.arch.library.nyu.edu/databases/proxy/NYU04564"
    And I am prompted with the login screen
    When I login as Cooper Union faculty
    Then I should be redirected to the EZProxy access denied page

  Scenario: Logging into EZProxy as NYSID faculty
    Given I am on "https://dev.arch.library.nyu.edu/databases/proxy/NYU04564"
    And I am prompted with the login screen
    When I login as NYSID faculty
    Then I should be redirected to the EZProxy access denied page
