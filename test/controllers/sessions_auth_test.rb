require "test_helper"

class SessionsAuthTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "caretaker@test.com", password: "sicherespasswort1234", role: "caretaker")
  end

  test "erfolgreicher Login leitet weiter und setzt Session-Cookie" do
    post session_path, params: { email: @user.email, password: "sicherespasswort1234" }
    assert_response :redirect
    session_cookie = response.cookies["session_id"]
    assert_not_nil session_cookie
  end

  test "falsches Passwort gibt 422 zurück" do
    post session_path, params: { email: @user.email, password: "falschespasswort1234" }
    assert_response :unprocessable_entity
  end

  test "unbekannte E-Mail gibt 422 zurück" do
    post session_path, params: { email: "unknown@test.com", password: "irgendeinpasswort1234" }
    assert_response :unprocessable_entity
  end

  test "Logout invalidiert die Session serverseitig" do
    post session_path, params: { email: @user.email, password: "sicherespasswort1234" }
    session_count_before = @user.sessions.count

    delete session_path
    assert_equal 0, @user.sessions.count
  end

  test "unauthentifizierter Zugriff auf geschützte Seite redirectet zu Login" do
    get children_path
    assert_response :redirect
    assert_redirected_to new_session_path
  end
end
