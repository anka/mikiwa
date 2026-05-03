require "application_system_test_case"

class CaretakerLoginTest < ApplicationSystemTestCase
  setup do
    @caretaker = User.create!(
      email: "caretaker_sys@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
    @admin = User.create!(
      email: "admin_sys@test.de",
      password: "sicherespasswort1234",
      role: "admin"
    )
  end

  teardown do
    @caretaker.destroy!
    @admin.destroy!
  end

  # TS-001-S01
  test "Betreuer loggt sich mit gültigem Passwort ein und landet auf Dashboard" do
    sign_in_via_ui @caretaker

    assert_current_path staff_dashboard_path
    assert_selector "h1"
  end

  # TS-001-S02
  test "Admin loggt sich ein und landet auf Staff-Dashboard" do
    sign_in_via_ui @admin

    assert_current_path staff_dashboard_path
  end
end
