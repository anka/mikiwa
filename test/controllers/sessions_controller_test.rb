require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "caretaker_ctrl@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
    @admin = User.create!(
      email: "admin_ctrl@test.de",
      password: "sicherespasswort1234",
      role: "admin"
    )
  end

  teardown do
    @caretaker.destroy!
    @admin.destroy!
  end

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email: @caretaker.email, password: "sicherespasswort1234" }

    assert_redirected_to staff_dashboard_path
    assert cookies[:session_id]
  end

  test "admin login redirects to staff dashboard" do
    post session_path, params: { email: @admin.email, password: "sicherespasswort1234" }

    assert_redirected_to staff_dashboard_path
  end

  test "create with invalid credentials" do
    post session_path, params: { email: @caretaker.email, password: "falschespasswort1234" }

    assert_response :unprocessable_entity
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@caretaker)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  # TS-002: Anti-Enumeration – beide Fehlerpfade liefern identischen Response
  test "TS-002 falsches Passwort gibt 422 ohne spezifische Fehlermeldung zurück" do
    post session_path, params: { email: @caretaker.email, password: "falschespasswort1234" }

    assert_response :unprocessable_entity
    assert_no_match(/E-Mail nicht gefunden/i, response.body)
    assert_no_match(/Passwort falsch/i, response.body)
  end

  test "TS-002 unbekannte E-Mail gibt 422 zurück" do
    post session_path, params: { email: "unbekannt@test.de", password: "irgendeinpasswort1234" }

    assert_response :unprocessable_entity
    assert_no_match(/E-Mail nicht gefunden/i, response.body)
    assert_no_match(/Passwort falsch/i, response.body)
  end

  test "TS-002 beide Fehlerpfade liefern HTTP 422 und keine verräterischen Nachrichten" do
    post session_path, params: { email: @caretaker.email, password: "falschespasswort1234" }
    assert_response :unprocessable_entity
    assert_no_match(/E-Mail nicht gefunden|Passwort (ist )?falsch|ungültig|incorrect password/i, response.body)

    post session_path, params: { email: "unbekannt@test.de", password: "passwort1234567890" }
    assert_response :unprocessable_entity
    assert_no_match(/E-Mail nicht gefunden|Passwort (ist )?falsch|ungültig|incorrect password/i, response.body)
  end

  # TS-005: Session Lifetime & Logout
  test "TS-005 Logout invalidiert Session serverseitig" do
    sign_in_as(@caretaker)
    session_count_before = @caretaker.sessions.count

    delete session_path

    assert_equal 0, @caretaker.reload.sessions.count
    assert_redirected_to new_session_path
  end

  test "TS-005 nach Logout ist geschützte Seite nicht erreichbar" do
    sign_in_as(@caretaker)
    delete session_path

    get children_path
    assert_redirected_to new_session_path
  end

  test "TS-005 abgelaufene Session leitet zu Login weiter" do
    sign_in_as(@caretaker)
    @caretaker.sessions.last.update_columns(created_at: 8.days.ago)

    get children_path
    assert_redirected_to new_session_path
  end
end
