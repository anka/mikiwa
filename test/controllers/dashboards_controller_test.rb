require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_a = Group.create!(name: "Bären")
    @group_b = Group.create!(name: "Löwen")

    @staff = User.create!(email: "staff_dash@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent_a = User.create!(email: "parent_a_dash@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @parent_b = User.create!(email: "parent_b_dash@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    @child_a = Child.create!(
      first_name: "Anna", last_name: "Huber",
      date_of_birth: Date.new(2021, 3, 10),
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "Ben", last_name: "Steiner",
      date_of_birth: Date.new(2020, 6, 20),
      group: @group_b, kindergarten_year: @year, photo_consent: true
    )

    ParentChild.create!(user: @parent_a, child: @child_a)
    ParentChild.create!(user: @parent_b, child: @child_b)
  end

  # ── F17: Eltern-Dashboard ─────────────────────────────────────────────────

  test "parent can access parent dashboard" do
    sign_in_as(@parent_a)
    get parent_dashboard_path
    assert_response :success
  end

  test "unauthenticated user is redirected from parent dashboard" do
    get parent_dashboard_path
    assert_redirected_to new_session_path
  end

  test "staff cannot access parent dashboard" do
    sign_in_as(@staff)
    get parent_dashboard_path
    assert_response :forbidden
  end

  test "parent dashboard shows unread messages section only when unread messages exist" do
    sign_in_as(@parent_a)

    # Without unread messages: section absent
    get parent_dashboard_path
    assert_response :success
    assert_select ".mw-dashboard-section--inbox", count: 0

    # Create a message for parent_a's group
    msg = Message.new(title: "Info", body: "Wichtig", sent_by: @staff)
    msg.message_groups.build(group: @group_a)
    msg.save!
    msg.deliver!

    get parent_dashboard_path
    assert_response :success
    assert_select ".mw-dashboard-section--inbox"
  end

  test "parent dashboard shows only own group events" do
    event_a = build_event("Waldtag Bären", @group_a, 3.days.from_now.to_date)
    event_b = build_event("Waldtag Löwen", @group_b, 5.days.from_now.to_date)

    sign_in_as(@parent_a)
    get parent_dashboard_path

    assert_select "body", text: /Waldtag Bären/
    assert_select "body", text: /Waldtag Löwen/, count: 0
  end

  test "parent dashboard data isolation – messages from other group not shown" do
    msg = Message.new(title: "Nur für Löwen", body: "Geheim", sent_by: @staff)
    msg.message_groups.build(group: @group_b)
    msg.save!
    msg.deliver!

    sign_in_as(@parent_a)
    get parent_dashboard_path
    assert_select ".mw-dashboard-section--inbox", count: 0
  end

  test "parent dashboard shows open attendance lists where parent has not entered" do
    list = AttendanceList.create!(
      title: "Ausflug-Liste", mode: "general",
      group: @group_a, kindergarten_year: @year, created_by: @staff
    )

    sign_in_as(@parent_a)
    get parent_dashboard_path
    assert_select ".mw-dashboard-section--open-lists"

    # After entering, the list disappears from section
    AttendanceEntry.create!(list: list, child: @child_a, user: @parent_a)
    get parent_dashboard_path
    # Section should either be gone or not contain this list
    assert_select ".mw-dashboard-entry[data-list-id='#{list.id}']", count: 0
  end

  test "parent dashboard shows meal plan for today and tomorrow" do
    today = Date.today
    MealEntry.create!(
      date: today, meal: "Nudeln mit Tomatensoße",
      group: @group_a, kindergarten_year: @year, created_by: @staff
    )
    MealEntry.create!(
      date: today + 1, meal: "Gemüsesuppe",
      group: @group_a, kindergarten_year: @year, created_by: @staff
    )

    sign_in_as(@parent_a)
    get parent_dashboard_path
    assert_select ".mw-dashboard-section--meals"
    assert_select "body", text: /Nudeln/
    assert_select "body", text: /Gemüsesuppe/
  end

  test "authenticated parent is redirected to parent dashboard from root" do
    sign_in_as(@parent_a)
    get root_path
    assert_redirected_to parent_dashboard_path
  end

  # ── F18: Betreuer-Dashboard ───────────────────────────────────────────────

  test "staff can access staff dashboard" do
    sign_in_as(@staff)
    get staff_dashboard_path
    assert_response :success
  end

  test "parent cannot access staff dashboard" do
    sign_in_as(@parent_a)
    get staff_dashboard_path
    assert_response :forbidden
  end

  test "unauthenticated user is redirected from staff dashboard" do
    get staff_dashboard_path
    assert_redirected_to new_session_path
  end

  test "authenticated staff is redirected to staff dashboard from root" do
    sign_in_as(@staff)
    get root_path
    assert_redirected_to staff_dashboard_path
  end

  test "staff dashboard open tasks shows past events without gallery" do
    past_event = build_event("Ausflug gestern", @group_a, 1.day.ago.to_date)

    sign_in_as(@staff)
    get staff_dashboard_path
    assert_select ".mw-dashboard-section--open-tasks"
    assert_select "body", text: /Ausflug gestern/
  end

  test "staff dashboard open tasks shows polls with active deadline" do
    poll = Poll.new(
      title: "Sommerfest Datum", poll_type: "single", status: "open",
      deadline: 7.days.from_now, group: @group_a, kindergarten_year: @year, created_by: @staff
    )
    poll.poll_options.build(label: "Samstag")
    poll.save!

    sign_in_as(@staff)
    get staff_dashboard_path
    assert_select "body", text: /Sommerfest Datum/
  end

  test "staff dashboard shows group statistics for active year" do
    sign_in_as(@staff)
    get staff_dashboard_path
    assert_select ".mw-dashboard-section--stats"
    assert_select "body", text: /Bären/
    assert_select "body", text: /Löwen/
  end

  test "staff dashboard quick actions include new message link" do
    sign_in_as(@staff)
    get staff_dashboard_path
    assert_select "a[href='#{new_message_path}']"
  end

  test "staff dashboard quick actions include new event link" do
    sign_in_as(@staff)
    get staff_dashboard_path
    assert_select "a[href='#{new_event_path}']"
  end

  test "staff dashboard quick actions include new child link" do
    sign_in_as(@staff)
    get staff_dashboard_path
    assert_select "a[href='#{new_child_path}']"
  end

  # F24: Caretaker-Dashboard Geburtstags-Hero mit Confetti
  test "F24 Staff-Dashboard zeigt Birthdays-Hero" do
    sign_in_as(@staff)
    get staff_dashboard_path
    assert_response :success
    assert_match(/mw-birthdays-hero/, response.body)
  end

  test "F24 Confetti-Container erscheint wenn Geburtstage in 7 Tagen anstehen" do
    sign_in_as(@staff)
    today = Date.current
    Child.create!(
      first_name: "Lina", last_name: "Geburtstag",
      date_of_birth: today.change(year: today.year - 4) + 3.days,
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    get staff_dashboard_path
    assert_response :success
    assert_match(/mw-confetti/, response.body)
    assert_match "Lina", response.body
  end

  test "F24 Kein Confetti-Container wenn keine Geburtstage in 7 Tagen" do
    sign_in_as(@staff)
    Child.where.not(id: nil).find_each do |c|
      c.update_columns(date_of_birth: Date.current.change(year: c.date_of_birth.year) + 60.days)
    end
    get staff_dashboard_path
    assert_response :success
    assert_no_match(/mw-confetti/, response.body)
  end

  private

  def build_event(title, group, date)
    event = Event.new(
      title: title, start_date: date, start_time: "10:00",
      kindergarten_year: @year, created_by: @staff
    )
    event.calendar_event_groups.build(group: group)
    event.save!
    event
  end
end
