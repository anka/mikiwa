require "test_helper"

class IcalCachingTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "ical_cache@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @user.ensure_ical_token!
  end

  teardown do
    @user.destroy!
  end

  # TS-055-S01: HTTP 304 wenn ETag unverändert
  test "TS-055 GET mit bekanntem ETag liefert HTTP 304" do
    get "/calendar/#{@user.ical_token}.ics"
    assert_response :success
    etag = response.headers["ETag"]
    assert etag.present?, "ETag-Header muss gesetzt sein"

    get "/calendar/#{@user.ical_token}.ics",
        headers: { "If-None-Match" => etag }
    assert_response :not_modified
  end
end
