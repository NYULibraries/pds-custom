Feature: Login to PDS for EZBorrow from off campus
  In order to find books in EZBorrow
  As an off campus user
  I would like to be directed to login through PDS.

  Background:
    Given I am off campus
    And I am logged out

  Scenario: Logging into EZBorrow as an NYU student
    Given I am on "https://pdsdev.library.nyu.edu/ezborrow?query=dasdasdsadad"
    And I am prompted with the login screen
    When I login as an NYU student
    Then I should be redirected to "e-zborrow"

  Scenario: Logging into EZBorrow as Cooper Union faculty
    Given I am on "https://pdsdev.library.nyu.edu/ezborrow?query=dasdasdsadad"
    And I am prompted with the login screen
    When I login as Cooper Union faculty
    Then I should be redirected to the EZBorrow access denied page

  Scenario: Logging into EZBorrow as NYSID faculty
    Given I am on "https://pdsdev.library.nyu.edu/ezborrow?query=dasdasdsadad"
    And I am prompted with the login screen
    When I login as NYSID faculty
    Then I should be redirected to the EZBorrow access denied page
