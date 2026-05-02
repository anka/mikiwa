require "test_helper"

class BouncesControllerTest < ActionDispatch::IntegrationTest
  test "Bounce-Webhook setzt email_invalid auf true" do
    user = User.create!(email: "bounced@example.com", password: "sicherespasswort1234")
    assert_not user.email_invalid?

    post "/webhooks/bounce", params: { email: user.email }, as: :json
    assert_response :ok

    user.reload
    assert user.email_invalid?
  end

  test "Bounce-Webhook mit unbekannter E-Mail liefert 200 ohne Fehler" do
    post "/webhooks/bounce", params: { email: "unknown@example.com" }, as: :json
    assert_response :ok
  end
end
