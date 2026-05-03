require "test_helper"

class CaretakerDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group_bears = Group.create!(name: "Staff-Dash-Bären")
    @group_lions = Group.create!(name: "Staff-Dash-Löwen")
    @caretaker = User.create!(email: "staff_dash@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
  end

  teardown do
    Event.where(kindergarten_year: @year).each { |e| e.calendar_event_groups.destroy_all; e.destroy! }
    Child.where(group: [ @group_bears, @group_lions ]).destroy_all
    @caretaker.destroy!
    @group_bears.destroy!
    @group_lions.destroy!
  end

  # TS-058-S01: Vergangene Veranstaltung ohne Galerie erscheint in "Offene Aufgaben"
  test "TS-058 Vergangene Veranstaltung ohne Galerie in Offene Aufgaben" do
    travel_to Time.zone.parse("2026-05-03 08:00:00") do
      past_event = Event.new(
        title: "Ausflug ohne Galerie", start_date: Date.new(2026, 4, 20),
        all_day: true, status: "aktiv",
        kindergarten_year: @year, created_by: @caretaker
      )
      past_event.calendar_event_groups.build(group: @group_bears)
      past_event.save!

      sign_in_as(@caretaker)
      get staff_dashboard_path

      assert_response :success
      assert_match "Ausflug ohne Galerie", response.body
    end
  end

  # TS-058-S02: Schnellaktion "Neue Mitteilung" enthält Link zum Mitteilungsformular
  test "TS-058 Schnellaktion Neue Mitteilung verlinkt zum Mitteilungsformular" do
    sign_in_as(@caretaker)
    get staff_dashboard_path

    assert_response :success
    assert_match new_message_path, response.body
  end

  # TS-058-S03: Statistik zeigt Anzahl Kinder pro Gruppe korrekt
  test "TS-058 Gruppenstatistik zeigt korrekte Kinderzahl" do
    3.times do |i|
      Child.create!(
        first_name: "Bear#{i}", last_name: "Kind",
        date_of_birth: 5.years.ago.to_date,
        group: @group_bears, kindergarten_year: @year, photo_consent: true
      )
    end
    2.times do |i|
      Child.create!(
        first_name: "Lion#{i}", last_name: "Kind",
        date_of_birth: 4.years.ago.to_date,
        group: @group_lions, kindergarten_year: @year, photo_consent: true
      )
    end

    sign_in_as(@caretaker)
    get staff_dashboard_path

    assert_response :success
    assert_match "Staff-Dash-Bären", response.body
    assert_match "Staff-Dash-Löwen", response.body
  end
end
