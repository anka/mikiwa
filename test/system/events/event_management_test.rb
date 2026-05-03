require "test_helper"

class EventManagementTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Event-Mgmt-Gruppe")
    @caretaker = User.create!(email: "event_mgmt@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
  end

  teardown do
    Event.where(created_by: @caretaker).destroy_all
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-038-S01: Betreuer legt Veranstaltung an
  test "TS-038 Betreuer legt Veranstaltung an" do
    sign_in_as(@caretaker)

    assert_difference "Event.count", 1 do
      post events_path, params: {
        event: {
          title: "Sommerfest 2026",
          start_date: "2026-07-01",
          all_day: true,
          status: "aktiv",
          kindergarten_year_id: @year.id,
          group_ids: [ @group.id ]
        }
      }
    end

    assert_response :redirect
  end

  # TS-038-S02: Betreuer sagt Veranstaltung ab
  test "TS-038 Betreuer sagt Veranstaltung ab" do
    event = Event.new(
      title: "Abzusagende Veranstaltung", start_date: Date.new(2026, 7, 1),
      all_day: true, status: "aktiv",
      kindergarten_year: @year, created_by: @caretaker
    )
    event.calendar_event_groups.build(group: @group)
    event.save!

    sign_in_as(@caretaker)
    patch cancel_event_path(event)
    assert_response :redirect

    event.reload
    assert_equal "abgesagt", event.status
  ensure
    event&.destroy!
  end
end
