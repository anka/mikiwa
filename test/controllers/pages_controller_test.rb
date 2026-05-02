require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home is reachable without authentication" do
    get root_path
    assert_response :success
  end
end
