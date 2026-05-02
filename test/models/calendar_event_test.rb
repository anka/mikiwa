require "test_helper"

class CalendarEventTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Bären")
    @year = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @creator = User.create!(email: "betreuer_ev@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @event = CalendarEvent.new(
      title: "Elternsprechtag",
      start_date: Date.new(2026, 6, 15),
      all_day: true,
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

  test "start_date is required" do
    @event.start_date = nil
    assert_not @event.save
    assert @event.errors[:start_date].any?
  end

  test "kindergarten_year is required" do
    @event.kindergarten_year = nil
    assert_not @event.save
    assert @event.errors[:kindergarten_year].any?
  end

  test "created_by is required" do
    @event.created_by = nil
    assert_not @event.save
    assert @event.errors[:created_by].any?
  end

  test "at least one group is required" do
    event = CalendarEvent.new(
      title: "Ohne Gruppe", start_date: Date.new(2026, 6, 15),
      all_day: true, kindergarten_year: @year, created_by: @creator
    )
    assert_not event.save
    assert event.errors[:groups].any?
  end

  test "event uses UUID primary key" do
    @event.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @event.id)
  end

  test "all_day defaults to true" do
    ev = CalendarEvent.new
    assert ev.all_day
  end

  test "event_type defaults to event" do
    @event.save!
    assert_equal "event", @event.event_type
  end

  test "non-all-day event requires start_time" do
    @event.all_day = false
    @event.start_time = nil
    assert_not @event.save
    assert @event.errors[:start_time].any?
  end

  test "all_day event does not require start_time" do
    @event.all_day = true
    @event.start_time = nil
    assert @event.save
  end

  test "for_year scope filters by kindergarten year" do
    @event.save!
    other_year = KindergartenYear.create!(
      label: "KGJ 2024/25", start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 7, 31)
    )
    other_event = CalendarEvent.new(
      title: "Anderes Ereignis", start_date: Date.new(2025, 6, 1),
      all_day: true, kindergarten_year: other_year, created_by: @creator
    )
    other_event.calendar_event_groups.build(group: @group)
    other_event.save!
    assert_includes CalendarEvent.for_year(@year), @event
    assert_not_includes CalendarEvent.for_year(@year), other_event
  end

  test "for_month scope filters by month" do
    @event.save!
    other_event = CalendarEvent.new(
      title: "Im Juli", start_date: Date.new(2026, 7, 1),
      all_day: true, kindergarten_year: @year, created_by: @creator
    )
    other_event.calendar_event_groups.build(group: @group)
    other_event.save!
    june = Date.new(2026, 6, 1)
    assert_includes CalendarEvent.for_month(june), @event
    assert_not_includes CalendarEvent.for_month(june), other_event
  end

  test "for_groups scope filters by group ids" do
    @event.save!
    other_group = Group.create!(name: "Löwen")
    other_event = CalendarEvent.new(
      title: "Nur Löwen", start_date: Date.new(2026, 6, 20),
      all_day: true, kindergarten_year: @year, created_by: @creator
    )
    other_event.calendar_event_groups.build(group: other_group)
    other_event.save!
    assert_includes CalendarEvent.for_groups([ @group.id ]), @event
    assert_not_includes CalendarEvent.for_groups([ @group.id ]), other_event
  end
end
