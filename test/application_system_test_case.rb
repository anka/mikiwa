require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  def sign_in_via_ui(user, password: "sicherespasswort1234")
    visit new_session_path
    fill_in "E-Mail-Adresse", with: user.email
    fill_in "Passwort", with: password
    click_button "Anmelden"
  end

  def sign_in_as_via_session(user)
    session = user.sessions.create!
    page.driver.browser.set_cookie("session_id=#{session.id}")
    visit root_path
  end
end
