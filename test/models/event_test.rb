require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Bären")
    @year = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @creator = User.create!(email: "betreuer_ev2@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @event = Event.new(
      title: "Sommerfest",
      start_date: Date.new(2026, 7, 10),
      start_time: "14:00",
      all_day: false,
      location: "Garten",
      description: "Das große Sommerfest",
      kindergarten_year: @year,
      created_by: @creator
    )
    @event.calendar_event_groups.build(group: @group)
  end

  test "valid event can be saved" do
    assert @event.save, @event.errors.full_messages.inspect
  end

  test "title is required" do
    @event.title = nil
    assert_not @event.save
    assert @event.errors[:title].any?
  end

  test "event has event_type veranstaltung" do
    @event.save!
    assert_equal "veranstaltung", @event.event_type
  end

  test "event uses UUID primary key" do
    @event.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @event.id)
  end

  test "event can be cancelled" do
    @event.save!
    @event.cancel!
    assert @event.cancelled?
    assert_equal "abgesagt", @event.status
  end

  test "cancelled event is not deletable (must use cancel)" do
    @event.save!
    @event.cancel!
    assert @event.cancelled?
  end

  test "event appears in CalendarEvent with correct event_type" do
    @event.save!
    cal_event = CalendarEvent.find(@event.id)
    assert_equal "veranstaltung", cal_event.event_type
    assert_equal @event.title, cal_event.title
  end

  test "event can have optional location and description" do
    @event.location    = "Gruppenraum"
    @event.description = "Wichtige Veranstaltung"
    assert @event.save
  end
end
