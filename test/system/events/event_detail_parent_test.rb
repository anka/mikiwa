require "test_helper"

class EventDetailParentTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "EventParent-Gruppe")
    @caretaker = User.create!(email: "evtparent_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "evtparent_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    @child = Child.create!(
      first_name: "EventKind", last_name: "A",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @event = Event.new(
      title: "Eltern-Test-Event", start_date: Date.new(2026, 6, 10),
      all_day: true, status: "aktiv",
      kindergarten_year: @year, created_by: @caretaker
    )
    @event.calendar_event_groups.build(group: @group)
    @event.save!
  end

  teardown do
    @event.destroy!
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-039-S01: Elternteil sieht Veranstaltungs-Detailseite
  test "TS-039 Elternteil sieht Detailseite für Veranstaltung seiner Gruppe" do
    sign_in_as(@parent)

    get event_path(@event)

    assert_response :success
    assert_match "Eltern-Test-Event", response.body
  end
end
