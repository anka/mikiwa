require "test_helper"

class IcalFeedTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group_bears = Group.create!(name: "Feed-Bären")
    @group_lions = Group.create!(name: "Feed-Löwen")
    @caretaker = User.create!(email: "feed_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "feed_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @child = Child.create!(
      first_name: "FeedKind", last_name: "A",
      date_of_birth: 5.years.ago.to_date,
      group: @group_bears, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)
    @parent.ensure_ical_token!

    @event_bears = CalendarEvent.new(
      title: "Bären-Fest-iCal", start_date: Date.new(2026, 6, 1),
      all_day: true, event_type: "event", status: "aktiv",
      kindergarten_year: @year, created_by: @caretaker
    )
    @event_bears.calendar_event_groups.build(group: @group_bears)
    @event_bears.save!

    @event_lions = CalendarEvent.new(
      title: "Löwen-Fest-iCal", start_date: Date.new(2026, 6, 2),
      all_day: true, event_type: "event", status: "aktiv",
      kindergarten_year: @year, created_by: @caretaker
    )
    @event_lions.calendar_event_groups.build(group: @group_lions)
    @event_lions.save!
  end

  teardown do
    [ @event_bears, @event_lions ].each do |e|
      e.calendar_event_groups.destroy_all
      e.destroy!
    end
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group_bears.destroy!
    @group_lions.destroy!
  end

  # TS-053-S01: Elternteil-Feed enthält nur Ereignisse der eigenen Gruppe
  test "TS-053 iCal-Feed enthält nur Ereignisse der eigenen Gruppe" do
    get "/calendar/#{@parent.ical_token}.ics"

    assert_response :success
    assert_match "text/calendar", response.content_type
    assert_match "BEGIN:VCALENDAR", response.body
    assert_match "Bären-Fest-iCal", response.body
    assert_no_match "Löwen-Fest-iCal", response.body
  end
end
