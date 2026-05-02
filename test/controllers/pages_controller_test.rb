require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home requires authentication" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "offline page is reachable without authentication" do
    get offline_path
    assert_response :success
  end
end
