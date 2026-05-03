require "test_helper"

class ManifestTest < ActionDispatch::IntegrationTest
  # TS-022-S01: Web App Manifest enthält alle Pflichtfelder
  test "TS-022 GET /manifest liefert gültiges PWA-Manifest" do
    get pwa_manifest_path, headers: { "Accept" => "application/json" }

    assert_response :success
    assert_equal "application/json", response.media_type

    manifest = JSON.parse(response.body)

    assert_equal "Mikiwa", manifest["name"]
    assert_equal "standalone", manifest["display"]
    assert_equal "/", manifest["start_url"]
    assert manifest["theme_color"].present?, "theme_color muss vorhanden sein"

    icons = manifest["icons"]
    assert icons.present?, "icons-Array muss vorhanden sein"
    sizes = icons.map { |i| i["sizes"] }
    assert_includes sizes, "192x192"
    assert_includes sizes, "512x512"
  end
end
