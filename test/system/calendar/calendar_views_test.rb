require "test_helper"

class CalendarViewsTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Kalender-Gruppe")
    @caretaker = User.create!(
      email: "cal_views@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @event = CalendarEvent.new(
      title: "Monatstest-Veranstaltung",
      start_date: Date.new(2026, 5, 15),
      all_day: true,
      status: "aktiv",
      event_type: "veranstaltung",
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @event.calendar_event_groups.build(group: @group)
    @event.save!
  end

  teardown do
    @event.calendar_event_groups.destroy_all
    @event.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-064-S01: Ereignis am 15. in Monatsansicht sichtbar
  test "TS-064 Ereignis am 15. erscheint in der Monatsansicht" do
    travel_to Date.new(2026, 5, 3) do
      sign_in_as(@caretaker)
      get calendar_events_path(view: "month", month: "2026-05")

      assert_response :success
      assert_match "Monatstest-Veranstaltung", response.body
    end
  end

  # TS-064-S02: Ereignis in Listenansicht chronologisch vorhanden
  test "TS-064 Ereignis erscheint in der Listenansicht" do
    travel_to Date.new(2026, 5, 3) do
      sign_in_as(@caretaker)
      get calendar_events_path(view: "list")

      assert_response :success
      assert_match "Monatstest-Veranstaltung", response.body
    end
  end
end
