require "test_helper"

class RoleEnforcementTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "role_enforce_caretaker@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    @caretaker.destroy!
  end

  # TS-011-S01: Betreuer erhält 403 für Admin-Route
  test "Betreuer erhält 403 beim Zugriff auf /admin/users" do
    sign_in_as(@caretaker)

    get admin_users_path

    assert_response :forbidden
  end
end
