require "test_helper"

class UnauthenticatedAccessTest < ActionDispatch::IntegrationTest
  # TS-012-S01: Unauthentifizierter Zugriff auf Dashboard → Redirect zu /login
  test "Dashboard ohne Session leitet zu /login weiter" do
    get staff_dashboard_path

    assert_response :redirect
    assert_redirected_to new_session_path
  end

  test "Kinder-Liste ohne Session leitet zu /login weiter" do
    get children_path

    assert_response :redirect
    assert_redirected_to new_session_path
  end

  test "Kalender ohne Session leitet zu /login weiter" do
    get calendar_events_path

    assert_response :redirect
    assert_redirected_to new_session_path
  end

  test "Eltern-Dashboard ohne Session leitet zu /login weiter" do
    get parent_dashboard_path

    assert_response :redirect
    assert_redirected_to new_session_path
  end
end
