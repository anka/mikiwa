require "test_helper"

class IcalTokenRotationTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(email: "token_rot_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @parent.ensure_ical_token!
  end

  teardown do
    @parent.destroy!
  end

  # TS-054-S01: Alter Token ungültig nach Rotation; neuer Token gültig
  test "TS-054 Alter Token ungültig nach Rotation; neuer Token gültig" do
    old_token = @parent.ical_token

    sign_in_as(@parent)
    patch rotate_ical_token_profile_path

    @parent.reload
    new_token = @parent.ical_token

    assert_not_equal old_token, new_token

    get "/calendar/#{old_token}.ics"
    assert_response :not_found

    get "/calendar/#{new_token}.ics"
    assert_response :success
  end
end
