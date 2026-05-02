require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_ev3@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_ev3@mikiwa.at",  password: SecureRandom.hex(20),   role: "parent")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Veranst-Bären")
    @group_loewen = Group.create!(name: "Veranst-Löwen")

    @child = Child.create!(
      first_name: "Lisa", last_name: "Kraft",
      date_of_birth: Date.new(2021, 3, 1),
      group: @group_baeren, kindergarten_year: @year,
      photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @event = build_event("Sommerfest", @group_baeren)
  end

  def build_event(title, group)
    ev = Event.new(
      title: title, start_date: Date.new(2026, 7, 10),
      start_time: "14:00", all_day: false,
      location: "Garten", kindergarten_year: @year,
      created_by: @caretaker
    )
    ev.calendar_event_groups.build(group: group)
    ev.save!
    ev
  end

  # --- Unauthenticated ---
  test "unauthenticated user is redirected" do
    get events_path
    assert_redirected_to new_session_path
  end

  # --- Index ---
  test "caretaker can access events list" do
    sign_in_as(@caretaker)
    get events_path
    assert_response :success
  end

  test "parent can access events list" do
    sign_in_as(@parent)
    get events_path
    assert_response :success
  end

  test "parent sees only events from own groups" do
    build_event("Ausflug Löwen", @group_loewen)
    sign_in_as(@parent)
    get events_path
    assert_match "Sommerfest", response.body
    assert_no_match "Ausflug Löwen", response.body
  end

  # --- Show ---
  test "caretaker can see event detail" do
    sign_in_as(@caretaker)
    get event_path(@event)
    assert_response :success
    assert_match "Sommerfest", response.body
  end

  test "parent can see event detail for own group" do
    sign_in_as(@parent)
    get event_path(@event)
    assert_response :success
  end

  test "parent cannot see event detail for other group (403)" do
    loewen_event = build_event("Löwen-Feier", @group_loewen)
    sign_in_as(@parent)
    get event_path(loewen_event)
    assert_response :forbidden
  end

  # --- Create ---
  test "caretaker can create event" do
    sign_in_as(@caretaker)
    assert_difference "Event.count", 1 do
      post events_path, params: {
        event: {
          title: "Neues Fest",
          start_date: "2026-07-15",
          start_time: "10:00",
          all_day: "0",
          location: "Turnsaal",
          description: "Beschreibung",
          kindergarten_year_id: @year.id,
          group_ids: [ @group_baeren.id ]
        }
      }
    end
    assert_redirected_to event_path(Event.order(:created_at).last)
  end

  test "event without title is rejected" do
    sign_in_as(@caretaker)
    assert_no_difference "Event.count" do
      post events_path, params: {
        event: {
          title: "", start_date: "2026-07-15",
          kindergarten_year_id: @year.id, group_ids: [ @group_baeren.id ]
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "parent cannot create event (403)" do
    sign_in_as(@parent)
    post events_path, params: {
      event: { title: "X", start_date: "2026-07-15", kindergarten_year_id: @year.id }
    }
    assert_response :forbidden
  end

  # --- Cancel ---
  test "caretaker can cancel event" do
    sign_in_as(@caretaker)
    patch cancel_event_path(@event)
    assert_redirected_to event_path(@event)
    assert @event.reload.cancelled?
  end

  test "parent cannot cancel event (403)" do
    sign_in_as(@parent)
    patch cancel_event_path(@event)
    assert_response :forbidden
  end

  # --- Delete ---
  test "caretaker can delete event" do
    sign_in_as(@caretaker)
    assert_difference "Event.count", -1 do
      delete event_path(@event)
    end
    assert_redirected_to events_path
  end

  test "parent cannot delete event (403)" do
    sign_in_as(@parent)
    delete event_path(@event)
    assert_response :forbidden
  end
end
