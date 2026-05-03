require "test_helper"

class IcalLinkInProfileTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "ical_profile@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    @caretaker.destroy!
  end

  # TS-037-S01: iCal-Link auf Profilseite vorhanden
  test "TS-037 Profilseite enthält personalisierten iCal-Link" do
    sign_in_as(@caretaker)

    get profile_path

    assert_response :success

    @caretaker.reload
    assert @caretaker.ical_token.present?, "ical_token muss gesetzt sein"
    assert_match @caretaker.ical_token, response.body
    assert_match ".ics", response.body
  end
end
