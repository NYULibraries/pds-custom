Given(/^I am off campus$/) do
end

Given(/^I am logged out$/) do

end

Given(/^I am on campus$/) do
end

Given(/^I am on "(.*?)"$/) do |url|
  visit url
end

Given(/^I am prompted with the login screen$/) do
  expect(page).to have_content 'Select your affiliation to login'
end

When(/^I login as an NYU student$/) do
  click_link 'NYU'
  username = fetch_username("nyu", "student")
  password = fetch_password("nyu", "student")
  step "I login to NYU Shibboleth with \"#{username}\":\"#{password}\""
end

When(/^I login as Cooper Union faculty$/) do
  click_link 'Cooper Union'
  username = fetch_username("cooper", "faculty")
  password = fetch_password("cooper", "faculty")
  step "I login to Aleph with \"#{username}\":\"#{password}\""
end

When(/^I login as NYSID faculty$/) do
  click_link 'NYSID'
  username = fetch_username("nysid", "faculty")
  password = fetch_password("nysid", "faculty")
  step "I login to Aleph with \"#{username}\":\"#{password}\""
end

Then(/^I should be redirected to "(.*?)"$/) do |url|
  expect(page.current_url).to match url
end

Then(/^I should be redirected to the EZProxy access denied page$/) do
  expect(page.current_url).to match "http://library.nyu.edu/errors/ezproxy-library-nyu-edu/unauthorized"
  expect(page).to have_content "EZProxy Login"
  expect(page).to have_content "We're sorry, but you are not authorized to access this content."
end

Then(/^I should be redirected to the EZBorrow access denied page$/) do
  expect(page.current_url).to match "http://library.nyu.edu/errors/ezborrow-library-nyu-edu/unauthorized"
  expect(page).to have_content "EZBorrow access is available to all NYU faculty, staff and students enrolled in degree or diploma programs."
  expect(page).to have_content "We're sorry, but you are not authorized to access this content."
end

When(/^I login to NYU Shibboleth with "(.*?)":"(.*?)"$/) do |username, password|
  within('#section_login') do
    fill_in 'j_username', with: username
    fill_in 'j_password', with: password
    click_button 'Login'
  end
end

When(/^I login to Aleph with "(.*?)":"(.*?)"$/) do |username, password|
  within('#aleph') do
    fill_in 'username', with: username
    fill_in 'password', with: password
    click_button 'Login'
  end
end

def fetch_username(institution,user_type)
  Figs.env[institution][user_type]["username"]
end

def fetch_password(institution,user_type)
  Figs.env[institution][user_type]["password"]
end
