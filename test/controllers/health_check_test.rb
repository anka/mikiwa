require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "GET /up liefert HTTP 200 wenn App läuft" do
    get rails_health_check_path
    assert_response :success
  end

  test "GET /up ist ohne Authentifizierung zugänglich" do
    get rails_health_check_path
    assert_not_equal 302, response.status
    assert_response :success
  end
end
