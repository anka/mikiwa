require "test_helper"

class CalendarEventsTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Cal-Bären")
    @caretaker = User.create!(email: "cal_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
  end

  teardown do
    CalendarEvent.where(created_by: @caretaker).each { |e| e.calendar_event_groups.destroy_all; e.destroy! }
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-036-S01: Betreuer legt Kalender-Ereignis an
  test "TS-036 Betreuer legt Kalender-Ereignis an" do
    sign_in_as(@caretaker)

    assert_difference "CalendarEvent.count", 1 do
      post calendar_events_path, params: {
        calendar_event: {
          title: "Sommerfest Bären",
          start_date: "2026-06-15",
          all_day: true,
          event_type: "event",
          status: "aktiv",
          kindergarten_year_id: @year.id,
          group_ids: [ @group.id ]
        }
      }
    end

    assert_response :redirect
    assert CalendarEvent.where(title: "Sommerfest Bären").exists?
  end

  # TS-036-S02: Event nur für bestimmte Gruppe sichtbar (Gruppen-Filterung)
  test "TS-036 Kalender-Ereignis erscheint im Kalender" do
    event = CalendarEvent.new(
      title: "Cal-Test-Event", start_date: Date.new(2026, 6, 15),
      all_day: true, event_type: "event", status: "aktiv",
      kindergarten_year: @year, created_by: @caretaker
    )
    event.calendar_event_groups.build(group: @group)
    event.save!

    sign_in_as(@caretaker)
    get calendar_events_path, params: { view: "list" }

    assert_response :success
    assert_match "Cal-Test-Event", response.body
  ensure
    event&.calendar_event_groups&.destroy_all
    event&.destroy!
  end
end
