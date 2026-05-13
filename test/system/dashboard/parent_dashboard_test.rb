require "test_helper"

class ParentDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Dashboard-Gruppe")
    @caretaker = User.create!(email: "dash_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "dash_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child = Child.create!(
      first_name: "DashKind", last_name: "Test",
      date_of_birth: Date.new(2026, 5, 10),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)
  end

  teardown do
    Message.where(sent_by: @caretaker).each do |m|
      m.inbox_entries.destroy_all
      m.message_groups.destroy_all
      m.destroy!
    end
    Event.where(created_by: @caretaker).each { |e| e.calendar_event_groups.destroy_all; e.destroy! }
    AttendanceList.where(created_by: @caretaker).each { |l| l.attendance_entries.destroy_all; l.destroy! }
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-056-S01: Alle Sektionen auf dem Dashboard vorhanden
  test "TS-056 Eltern-Dashboard zeigt Daten in allen Sektionen" do
    travel_to Time.zone.parse("2026-05-03 08:00:00") do
      message = Message.new(title: "Dashboard-Test-Msg", body: "Text.", sent_by: @caretaker)
      message.message_groups.build(group: @group)
      message.save!
      message.inbox_entries.create!(user: @parent)

      event = Event.new(
        title: "Dashboard-Event", start_date: Date.new(2026, 5, 15),
        all_day: true, status: "aktiv",
        kindergarten_year: @year, created_by: @caretaker
      )
      event.calendar_event_groups.build(group: @group)
      event.save!

      list = AttendanceList.create!(
        title: "Dashboard-Liste", mode: "general",
        group: @group, kindergarten_year: @year,
        created_by: @caretaker, deadline: 1.week.from_now
      )

      sign_in_as(@parent)
      get parent_dashboard_path

      assert_response :success
      assert_match "Dashboard-Test-Msg", response.body
      assert_match "Dashboard-Event",    response.body
      assert_match "Dashboard-Liste",    response.body
    end
  end

  # TS-056-S02: Leeres Dashboard ohne Fehler
  test "TS-056 Leeres Dashboard lädt ohne Fehler" do
    fresh_parent = User.create!(email: "dash_fresh@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    sign_in_as(fresh_parent)
    get parent_dashboard_path

    assert_response :success
  ensure
    fresh_parent&.destroy!
  end
end
