require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(
      email: "profil@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Elke",
      last_name: "Maier",
      phone: "0664 000 100"
    )
  end

  test "Elternteil kann eigenes Profil aufrufen" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
  end

  test "Elternteil kann Telefonnummer ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { phone: "0676 555 444" } }
    assert_equal "0676 555 444", @parent.reload.phone
    assert_redirected_to profile_path
  end

  test "Elternteil kann E-Mail ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { email: "neu@test.at" } }
    assert_equal "neu@test.at", @parent.reload.email
  end

  test "Elternteil kann Rolle nicht selbst ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { role: "admin" } }
    assert_equal "parent", @parent.reload.role
  end

  test "Profil zeigt iCal-Abo-Link" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
    assert_match ".ics", response.body
    assert @parent.reload.ical_token.present?
  end

  test "Token-Rotation erzeugt neuen Token" do
    sign_in_as(@parent)
    get profile_path
    old_token = @parent.reload.ical_token
    patch rotate_ical_token_profile_path
    assert_redirected_to profile_path
    assert_not_equal old_token, @parent.reload.ical_token
  end
end
