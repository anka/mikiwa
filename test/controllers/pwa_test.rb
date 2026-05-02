require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "manifest.json ist erreichbar und hat korrekte Struktur" do
    get "/manifest.json"
    assert_response :success
    manifest = JSON.parse(response.body)

    assert_equal "Mikiwa", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/", manifest["start_url"]
    assert_not_nil manifest["theme_color"]
    assert_not_nil manifest["background_color"]

    icons = manifest["icons"]
    assert icons.any? { |i| i["sizes"].include?("192x192") }, "Kein 192x192 Icon"
    assert icons.any? { |i| i["sizes"].include?("512x512") }, "Kein 512x512 Icon"
  end

  test "service-worker.js ist erreichbar" do
    get "/service-worker.js"
    assert_response :success
    assert_includes response.content_type, "javascript"
  end

  test "offline-Seite ist erreichbar" do
    get "/offline"
    assert_response :success
  end
end
