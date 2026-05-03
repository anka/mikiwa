require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "admin_access_caretaker@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
    @parent = User.create!(
      email: "admin_access_parent@test.de",
      password: "sicherespasswort1234",
      role: "parent"
    )
  end

  teardown do
    @caretaker.destroy!
    @parent.destroy!
  end

  # TS-025-S01: Betreuer → /admin → 403
  test "Betreuer erhält 403 für GET /admin" do
    sign_in_as(@caretaker)

    get admin_users_path

    assert_response :forbidden
  end

  # TS-025-S02: Elternteil → /admin → 403
  test "Elternteil erhält 403 für GET /admin" do
    sign_in_as(@parent)

    get admin_users_path

    assert_response :forbidden
  end

  test "Admin-Lock-Route für Betreuer gesperrt" do
    target = User.create!(email: "locktarget@test.de", password: "sicherespasswort1234", role: "caretaker")

    sign_in_as(@caretaker)
    patch lock_admin_user_path(target)
    assert_response :forbidden
  ensure
    target&.destroy!
  end
end
