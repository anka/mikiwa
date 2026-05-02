require "test_helper"

class Admin::PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "pagesadmin@mikiwa.at",
      password: "adminpasswort1234567",
      role: "admin"
    )
    @caretaker = User.create!(
      email: "pagescaretest@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  test "Impressum ist als statische Seite erreichbar (öffentlich)" do
    get impressum_path
    assert_response :success
    assert_match "Impressum", response.body
  end

  test "Datenschutzerklärung ist als statische Seite erreichbar (öffentlich)" do
    get datenschutz_path
    assert_response :success
    assert_match "Datenschutz", response.body
  end
end
