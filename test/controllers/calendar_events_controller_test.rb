require "test_helper"

class CalendarEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_cal@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_cal@mikiwa.at",  password: SecureRandom.hex(20),   role: "parent")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Bären")
    @group_loewen = Group.create!(name: "Löwen")

    @child = Child.create!(
      first_name: "Finn", last_name: "Berger",
      date_of_birth: Date.new(2021, 5, 10),
      group: @group_baeren, kindergarten_year: @year,
      photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @event_baeren = CalendarEvent.new(
      title: "Waldtag Bären", start_date: Date.new(2026, 6, 10),
      all_day: true, kindergarten_year: @year, created_by: @caretaker
    )
    @event_baeren.calendar_event_groups.build(group: @group_baeren)
    @event_baeren.save!

    @event_loewen = CalendarEvent.new(
      title: "Ausflug Löwen", start_date: Date.new(2026, 6, 15),
      all_day: true, kindergarten_year: @year, created_by: @caretaker
    )
    @event_loewen.calendar_event_groups.build(group: @group_loewen)
    @event_loewen.save!
  end

  # --- Unauthenticated access ---
  test "unauthenticated user is redirected to login" do
    get calendar_events_path
    assert_redirected_to new_session_path
  end

  # --- Caretaker access ---
  test "caretaker can access calendar" do
    sign_in_as(@caretaker)
    get calendar_events_path
    assert_response :success
  end

  test "caretaker sees all events" do
    sign_in_as(@caretaker)
    get calendar_events_path, params: { view: "list" }
    assert_match "Waldtag Bären", response.body
    assert_match "Ausflug Löwen", response.body
  end

  test "caretaker can create event" do
    sign_in_as(@caretaker)
    assert_difference "CalendarEvent.count", 1 do
      post calendar_events_path, params: {
        calendar_event: {
          title: "Elternabend",
          start_date: "2026-06-20",
          all_day: "1",
          location: "Gruppenraum",
          description: "Wichtige Infos",
          kindergarten_year_id: @year.id,
          group_ids: [ @group_baeren.id ]
        }
      }
    end
    assert_redirected_to calendar_events_path
    assert_equal "Elternabend", CalendarEvent.order(:created_at).last.title
  end

  test "event without title is rejected" do
    sign_in_as(@caretaker)
    assert_no_difference "CalendarEvent.count" do
      post calendar_events_path, params: {
        calendar_event: {
          title: "",
          start_date: "2026-06-20",
          all_day: "1",
          kindergarten_year_id: @year.id,
          group_ids: [ @group_baeren.id ]
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "event without groups is rejected" do
    sign_in_as(@caretaker)
    assert_no_difference "CalendarEvent.count" do
      post calendar_events_path, params: {
        calendar_event: {
          title: "Ohne Gruppe",
          start_date: "2026-06-20",
          all_day: "1",
          kindergarten_year_id: @year.id,
          group_ids: []
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "caretaker can edit and update event" do
    sign_in_as(@caretaker)
    get edit_calendar_event_path(@event_baeren)
    assert_response :success

    patch calendar_event_path(@event_baeren), params: {
      calendar_event: {
        title: "Waldtag Bären – aktualisiert",
        start_date: @event_baeren.start_date.to_s,
        all_day: "1",
        kindergarten_year_id: @year.id,
        group_ids: [ @group_baeren.id ]
      }
    }
    assert_redirected_to calendar_events_path
    assert_equal "Waldtag Bären – aktualisiert", @event_baeren.reload.title
  end

  test "caretaker can delete event" do
    sign_in_as(@caretaker)
    assert_difference "CalendarEvent.count", -1 do
      delete calendar_event_path(@event_baeren)
    end
    assert_redirected_to calendar_events_path
  end

  # --- Parent access ---
  test "parent can access calendar" do
    sign_in_as(@parent)
    get calendar_events_path
    assert_response :success
  end

  test "parent sees only events from own groups (Eltern-Filterung)" do
    sign_in_as(@parent)
    get calendar_events_path, params: { view: "list" }
    assert_match "Waldtag Bären", response.body
    assert_no_match "Ausflug Löwen", response.body
  end

  test "parent cannot create event (403)" do
    sign_in_as(@parent)
    post calendar_events_path, params: {
      calendar_event: {
        title: "Elternabend", start_date: "2026-06-20", all_day: "1",
        kindergarten_year_id: @year.id, group_ids: [ @group_baeren.id ]
      }
    }
    assert_response :forbidden
  end

  test "parent cannot edit event (403)" do
    sign_in_as(@parent)
    get edit_calendar_event_path(@event_baeren)
    assert_response :forbidden
  end

  test "parent cannot delete event (403)" do
    sign_in_as(@parent)
    delete calendar_event_path(@event_baeren)
    assert_response :forbidden
  end

  # --- Non-all-day event ---
  test "caretaker can create non-all-day event with time" do
    sign_in_as(@caretaker)
    assert_difference "CalendarEvent.count", 1 do
      post calendar_events_path, params: {
        calendar_event: {
          title: "Spielstunde",
          start_date: "2026-06-10",
          all_day: "0",
          start_time: "09:00",
          kindergarten_year_id: @year.id,
          group_ids: [ @group_baeren.id ]
        }
      }
    end
    ev = CalendarEvent.order(:created_at).last
    assert_not ev.all_day
    assert_equal "09:00", ev.start_time
  end
end
