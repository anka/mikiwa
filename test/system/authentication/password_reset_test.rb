require "test_helper"

class PasswordResetTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    @caretaker = User.create!(
      email: "pw_reset@test.de",
      password: "altespasswort123456",
      role: "caretaker"
    )
  end

  teardown do
    ActionMailer::Base.deliveries.clear
    @caretaker.destroy!
  end

  # TS-007-S01: vollständiger Reset-Flow
  test "Passwort-Reset vollständig: E-Mail, Token-Link, neues Passwort, Login" do
    perform_enqueued_jobs do
      post passwords_path, params: { email: @caretaker.email }
    end

    assert_equal 1, ActionMailer::Base.deliveries.size

    mail = ActionMailer::Base.deliveries.last
    mail_text = mail.text_part&.body&.decoded || mail.body.decoded
    url = mail_text[/https?:\/\/[^\s]+\/passwords\/[^\s]+\/edit/]
    assert_not_nil url, "Kein Reset-Link in der E-Mail gefunden"
    token = url[%r{/passwords/([^/\s]+)/edit}, 1]
    assert_not_nil token

    get edit_password_path(token)
    assert_response :success

    new_password = "neuespasswort123456"
    patch password_path(token), params: {
      password: new_password,
      password_confirmation: new_password
    }
    assert_redirected_to new_session_path

    post session_path, params: { email: @caretaker.email, password: new_password }
    assert_redirected_to staff_dashboard_path

    assert_nil User.find_by_password_reset_token(token), "Alter Token sollte nach Nutzung ungültig sein"
  end

  # TS-007-S02: abgelaufener Reset-Token
  test "abgelaufener Reset-Token zeigt Fehlermeldung" do
    token = nil

    travel_to 2.hours.ago do
      token = @caretaker.password_reset_token
    end

    get edit_password_path(token)

    assert_redirected_to new_password_path
    follow_redirect!
    assert_match(/ungültig oder abgelaufen/, response.body)
  end
end
