require "test_helper"

class CaretakerDashboardIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "DashConsent-Gruppe")
    @caretaker = User.create!(email: "dashconsent_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
  end

  teardown do
    Child.where(group: @group).destroy_all
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-059-S01: Kind ohne photo_consent (nil) erscheint in Offene Aufgaben
  test "TS-059 Kind ohne Foto-Einwilligung erscheint in offenen Aufgaben" do
    child_no_consent = Child.create!(
      first_name: "OhneEinwilligung", last_name: "X",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year,
      photo_consent: true
    )
    child_no_consent.update_column(:photo_consent, nil)

    sign_in_as(@caretaker)
    get staff_dashboard_path

    assert_response :success
    assert_match "Kinder ohne Foto-Einwilligung", response.body
  end
end
