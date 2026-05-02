require "test_helper"

class IcalFeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_a = Group.create!(name: "iCal-Bären")
    @group_b = Group.create!(name: "iCal-Löwen")
    @year    = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_ical@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_ical@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @child  = Child.create!(
      first_name: "Mia", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @staff.ensure_ical_token!
    @parent.ensure_ical_token!

    @event_a = CalendarEvent.new(
      title: "Gruppenausflug Bären", start_date: Date.new(2026, 6, 1),
      all_day: true, event_type: "event",
      kindergarten_year: @year, created_by: @staff
    )
    @event_a.calendar_event_groups.build(group: @group_a)
    @event_a.save!

    @event_b = CalendarEvent.new(
      title: "Löwen-Fest", start_date: Date.new(2026, 6, 15),
      all_day: true, event_type: "event",
      kindergarten_year: @year, created_by: @staff
    )
    @event_b.calendar_event_groups.build(group: @group_b)
    @event_b.save!
  end

  test "valid token returns 200 with text/calendar" do
    get "/calendar/#{@staff.ical_token}.ics"
    assert_response :success
    assert_match "text/calendar", response.content_type
  end

  test "invalid token returns 404" do
    get "/calendar/invalid_token_xyz.ics"
    assert_response :not_found
  end

  test "response includes X-Robots-Tag noindex" do
    get "/calendar/#{@staff.ical_token}.ics"
    assert_equal "noindex", response.headers["X-Robots-Tag"]
  end

  test "feed contains VCALENDAR structure" do
    get "/calendar/#{@staff.ical_token}.ics"
    assert_match "BEGIN:VCALENDAR", response.body
    assert_match "END:VCALENDAR", response.body
    assert_match "VERSION:2.0", response.body
  end

  test "staff feed contains events from all groups" do
    get "/calendar/#{@staff.ical_token}.ics"
    assert_match "Gruppenausflug B", response.body
    assert_match "L\xC3\xB6wen-Fest".force_encoding("UTF-8"), response.body
  end

  test "parent feed contains only events from their group" do
    get "/calendar/#{@parent.ical_token}.ics"
    assert_match "Gruppenausflug B", response.body
    assert_no_match "Löwen-Fest", response.body
  end

  test "token rotation invalidates old token" do
    old_token = @parent.ical_token
    @parent.rotate_ical_token!
    get "/calendar/#{old_token}.ics"
    assert_response :not_found
  end

  test "new token after rotation is valid" do
    @parent.rotate_ical_token!
    get "/calendar/#{@parent.ical_token}.ics"
    assert_response :success
  end

  test "ETag header is present" do
    get "/calendar/#{@staff.ical_token}.ics"
    assert response.headers["ETag"].present?
  end

  test "returns 304 when ETag matches" do
    get "/calendar/#{@staff.ical_token}.ics"
    etag = response.headers["ETag"]
    get "/calendar/#{@staff.ical_token}.ics",
        headers: { "If-None-Match" => etag }
    assert_response :not_modified
  end
end
