require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "security_headers@test.de",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    @caretaker.destroy!
  end

  # TS-018-S01: X-Robots-Tag Header ist gesetzt
  test "TS-018 X-Robots-Tag: noindex, nofollow bei GET /dashboard" do
    sign_in_as(@caretaker)

    get staff_dashboard_path

    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  # TS-018-S02: Content-Security-Policy Header vorhanden ohne externe Script-Src
  test "TS-018 Content-Security-Policy Header vorhanden" do
    sign_in_as(@caretaker)

    get staff_dashboard_path

    csp = response.headers["Content-Security-Policy"]
    assert csp.present?, "Content-Security-Policy Header muss vorhanden sein"
    assert_match "script-src", csp
    assert_no_match "http://", csp, "CSP darf keine externen HTTP-Domains in script-src enthalten"
    assert_no_match "https://cdn.", csp, "CSP darf keine externen CDN-Domains enthalten"
  end

  # TS-018-S03: POST ohne CSRF-Token wird abgewiesen
  test "TS-018 POST ohne CSRF-Token liefert 422" do
    sign_in_as(@caretaker)

    post children_path, headers: { "X-CSRF-Token" => "ungueltig" }

    assert_includes [ 400, 422 ], response.status, "POST ohne gültigen CSRF-Token muss 400 oder 422 liefern"
  end
end
