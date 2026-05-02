require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "admin@mikiwa.at",
      password: "adminpasswort1234567",
      role: "admin",
      first_name: "Admin",
      last_name: "User"
    )
    @caretaker = User.create!(
      email: "betreuer@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker",
      first_name: "Sabine",
      last_name: "Baum"
    )
    @other_admin = User.create!(
      email: "admin2@mikiwa.at",
      password: "adminpasswort9876543",
      role: "admin",
      first_name: "Klaus",
      last_name: "Berg"
    )
  end

  # --- Zugriffsschutz ---

  test "Betreuer kann Admin-Bereich nicht aufrufen (403)" do
    sign_in_as(@caretaker)
    get admin_users_path
    assert_response :forbidden
  end

  test "Nicht-angemeldeter User wird zu Login weitergeleitet" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "Admin kann Benutzerliste aufrufen" do
    sign_in_as(@admin)
    get admin_users_path
    assert_response :success
  end

  # --- Einladen ---

  test "Admin kann neuen Betreuer einladen" do
    sign_in_as(@admin)
    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: { email: "neu@mikiwa.at", role: "caretaker", first_name: "Neu", last_name: "Betreuer" }
      }
    end
    new_user = User.find_by!(email: "neu@mikiwa.at")
    assert_equal "caretaker", new_user.role
    assert_equal @admin, new_user.invited_by
  end

  test "Einladungs-E-Mail wird beim Anlegen verschickt" do
    sign_in_as(@admin)
    assert_emails 1 do
      post admin_users_path, params: {
        user: { email: "einladung@mikiwa.at", role: "caretaker", first_name: "Gast", last_name: "User" }
      }
    end
  end

  # --- Sperren / Entsperren ---

  test "Admin kann Betreuer sperren" do
    sign_in_as(@admin)
    patch lock_admin_user_path(@caretaker)
    assert @caretaker.reload.locked?
  end

  test "Admin kann gesperrten Account reaktivieren" do
    @caretaker.lock!
    sign_in_as(@admin)
    patch unlock_admin_user_path(@caretaker)
    assert_not @caretaker.reload.locked?
  end

  test "Admin kann sich nicht selbst sperren" do
    sign_in_as(@admin)
    patch lock_admin_user_path(@admin)
    assert_not @admin.reload.locked?
    assert_response :unprocessable_entity
  end

  # --- Löschen ---

  test "Admin kann Betreuer-Account löschen" do
    sign_in_as(@admin)
    assert_difference "User.count", -1 do
      delete admin_user_path(@caretaker)
    end
  end

  test "Admin kann sich nicht selbst löschen" do
    sign_in_as(@admin)
    assert_no_difference "User.count" do
      delete admin_user_path(@admin)
    end
    assert_response :unprocessable_entity
  end

  # --- Gesperrter Login ---

  test "Gesperrter User kann sich nicht einloggen" do
    @caretaker.lock!
    sign_in_as(@admin)
    sign_out
    # gesperrter User versucht Login
    post session_path, params: { email: @caretaker.email, password: "sicherespasswort1234" }
    assert_response :unprocessable_entity
  end
end
