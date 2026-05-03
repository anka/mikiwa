require "test_helper"

class Webhooks::MailjetControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "bounce@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    @user.destroy!
  end

  # TS-009-S01: Bounce-Webhook setzt email_invalid auf true
  test "Bounce-Webhook setzt email_invalid persistent auf true" do
    assert_not @user.email_invalid?

    post webhooks_bounce_path, params: { email: @user.email }

    assert_response :ok
    assert @user.reload.email_invalid?, "email_invalid sollte nach Bounce true sein"
  end

  test "Bounce-Webhook ist case-insensitive bei E-Mail-Adresse" do
    post webhooks_bounce_path, params: { email: @user.email.upcase }

    assert_response :ok
    assert @user.reload.email_invalid?
  end

  test "Bounce-Webhook mit unbekannter E-Mail gibt 200 zurück" do
    post webhooks_bounce_path, params: { email: "nichtvorhanden@test.de" }

    assert_response :ok
  end
end
