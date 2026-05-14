require "test_helper"

class CalendarEventsFilterTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "f67_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @year = KindergartenYear.create!(
      label: "F67-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "F67-Gruppe")

    @fest = CalendarEvent.new(
      title: "Sommerfest", start_date: Date.new(2026, 5, 10),
      all_day: true, kindergarten_year: @year, created_by: @caretaker
    )
    @fest.calendar_event_groups.build(group: @group)
    @fest.save!

    @waldtag = CalendarEvent.new(
      title: "Waldtag", start_date: Date.new(2026, 5, 14),
      all_day: true, kindergarten_year: @year, created_by: @caretaker
    )
    @waldtag.calendar_event_groups.build(group: @group)
    @waldtag.save!
  end

  test "F67 mw-filters Markup vorhanden" do
    sign_in_as(@caretaker)
    get calendar_events_path(view: "list")
    assert_response :success
    assert_select "form.mw-filters"
    assert_select ".mw-filters__search"
    assert_select ".mw-filters__search-icon"
    assert_select "input[name='q'].mw-filters__search-input"
    assert_select "select[name='kindergarten_year_id'].mw-filters__select"
    assert_select "select[name='group_id'].mw-filters__select"
  end

  test "F67 Titel-Suche filtert Events" do
    sign_in_as(@caretaker)
    get calendar_events_path(view: "list", q: "Fest")
    assert_response :success
    assert_match "Sommerfest", response.body
    assert_no_match "Waldtag", response.body
  end

  test "F67 Reset-Link mit Count-Badge bei aktiven Filtern" do
    sign_in_as(@caretaker)
    get calendar_events_path(view: "list", q: "Fest", group_id: @group.id)
    assert_response :success
    assert_select ".mw-filters__reset"
    assert_select ".mw-filters__reset-count"
  end

  test "F67 Reset-Link verschwindet ohne aktive Filter (außer Default-Jahr)" do
    sign_in_as(@caretaker)
    get calendar_events_path(view: "list")
    assert_response :success
    # Default-Jahr ist kein aktiver Filter
    assert_select ".mw-filters__reset", count: 0
  end

  test "F67 View-Toggle Monat/Liste bleibt funktional" do
    sign_in_as(@caretaker)
    get calendar_events_path(view: "list")
    assert_response :success
    assert_select "a[href*='view=month']"
    assert_select "a[href*='view=list']"
  end
end
