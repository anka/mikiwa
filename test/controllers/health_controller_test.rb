require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  # TS-019-S01: GET /up liefert HTTP 200
  test "TS-019 GET /up liefert HTTP 200" do
    get rails_health_check_path

    assert_response :success
  end
end
