require "test_helper"

class SiblingScopingTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "sibling_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "sibling_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    @group_bears = Group.create!(name: "Sibling-Bären")
    @group_lions = Group.create!(name: "Sibling-Löwen")

    @child_a = Child.create!(
      first_name: "Kind", last_name: "SibA",
      date_of_birth: 5.years.ago.to_date,
      group: @group_bears, kindergarten_year: @year, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "Kind", last_name: "SibB",
      date_of_birth: 4.years.ago.to_date,
      group: @group_lions, kindergarten_year: @year, photo_consent: true
    )

    ParentChild.create!(user: @parent, child: @child_a)
    ParentChild.create!(user: @parent, child: @child_b)

    @event_bears = CalendarEvent.new(
      title: "Bären-Event", start_date: Date.tomorrow, kindergarten_year: @year,
      created_by: @caretaker, event_type: "event", status: "aktiv", all_day: true
    )
    @event_bears.calendar_event_groups.build(group: @group_bears)
    @event_bears.save!

    @event_lions = CalendarEvent.new(
      title: "Löwen-Event", start_date: Date.tomorrow, kindergarten_year: @year,
      created_by: @caretaker, event_type: "event", status: "aktiv", all_day: true
    )
    @event_lions.calendar_event_groups.build(group: @group_lions)
    @event_lions.save!
  end

  teardown do
    @event_bears.destroy!
    @event_lions.destroy!
    ParentChild.where(user: @parent).destroy_all
    @child_a.destroy!
    @child_b.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group_bears.destroy!
    @group_lions.destroy!
  end

  # TS-029-S01: Elternteil mit Kindern in zwei Gruppen sieht Events beider Gruppen
  test "TS-029 Elternteil mit Kindern in zwei Gruppen sieht Events beider Gruppen" do
    sign_in_as(@parent)

    get calendar_events_path

    assert_response :success
    assert_match "Bären-Event", response.body
    assert_match "Löwen-Event", response.body
  end
end
