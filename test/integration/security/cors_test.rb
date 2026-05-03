require "test_helper"

class CorsTest < ActionDispatch::IntegrationTest
  # TS-073-S01: OPTIONS-Preflight von externer Origin bekommt keinen CORS-Header
  test "TS-073 OPTIONS-Request von fremder Origin erhält keinen Access-Control-Allow-Origin Header" do
    process :options, children_path, headers: {
      "Origin" => "https://evil.example.com",
      "Access-Control-Request-Method" => "GET"
    }

    assert_nil response.headers["Access-Control-Allow-Origin"],
      "Access-Control-Allow-Origin darf nicht gesetzt sein"
  end

  test "TS-073 GET-Request von fremder Origin erhält keinen Access-Control-Allow-Origin Header" do
    get new_session_path, headers: { "Origin" => "https://evil.example.com" }

    assert_nil response.headers["Access-Control-Allow-Origin"],
      "Access-Control-Allow-Origin darf nicht gesetzt sein"
  end
end
