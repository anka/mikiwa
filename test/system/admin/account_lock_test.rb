require "test_helper"

class AccountLockTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "admin_lock@mikiwa.at",
      password: "sicherespasswort1234",
      role: "admin"
    )
    @target = User.create!(
      email: "lock_target@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    @target.destroy!
    @admin.destroy!
  end

  # TS-024-S01: Admin sperrt Account – gesperrter User kann sich nicht einloggen
  test "TS-024 gesperrter Account kann sich nicht mehr einloggen" do
    sign_in_as(@admin)
    patch lock_admin_user_path(@target)
    assert_response :redirect

    @target.reload
    assert @target.locked?, "Account muss gesperrt sein"

    delete session_path
    post session_path, params: { email: @target.email, password: "sicherespasswort1234" }
    assert_response :unprocessable_entity
  end

  # TS-024-S02: Admin reaktiviert gesperrten Account
  test "TS-024 reaktivierter Account kann sich wieder einloggen" do
    @target.lock!

    sign_in_as(@admin)
    patch unlock_admin_user_path(@target)
    assert_response :redirect

    @target.reload
    assert_not @target.locked?, "Account muss entsperrt sein"

    delete session_path
    post session_path, params: { email: @target.email, password: "sicherespasswort1234" }
    assert_response :redirect
  end

  # TS-024-S03: Admin kann sich nicht selbst sperren
  test "TS-024 Admin kann sich nicht selbst sperren" do
    sign_in_as(@admin)
    patch lock_admin_user_path(@admin)

    assert_response :unprocessable_entity
    @admin.reload
    assert_not @admin.locked?, "Admin darf sich nicht selbst sperren"
  end
end
