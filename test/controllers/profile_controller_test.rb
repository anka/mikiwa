require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(
      email: "profil@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Elke",
      last_name: "Maier"
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
end
