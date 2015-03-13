Feature: Login to PDS for EZProxy from on campus
  In order to use authorized resources
  As an on campus researcher
  I would like to be directed to login through EZProxy.

  Background:
    Given I am on campus

  Scenario: Visiting protected url
    Given I visit "https://dev.arch.library.nyu.edu/databases/proxy/NYU04564"
    Then I should be redirected to "ebscohost.com.ezproxybeta.library.nyu.edu"
