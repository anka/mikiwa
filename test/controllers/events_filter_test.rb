require "test_helper"

class EventsFilterTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "f69_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @year = KindergartenYear.create!(
      label: "F69-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "F69-Gruppe")

    @fest = Event.new(
      title: "Sommerfest", start_date: Date.new(2026, 5, 10),
      all_day: true, kindergarten_year: @year, created_by: @caretaker
    )
    @fest.calendar_event_groups.build(group: @group)
    @fest.save!

    @ausflug = Event.new(
      title: "Zoo-Ausflug", start_date: Date.new(2026, 5, 14),
      all_day: true, kindergarten_year: @year, created_by: @caretaker
    )
    @ausflug.calendar_event_groups.build(group: @group)
    @ausflug.save!
    @ausflug.cancel!
  end

  test "F69 mw-filters Markup vorhanden" do
    sign_in_as(@caretaker)
    get events_path
    assert_response :success
    assert_select "form.mw-filters"
    assert_select ".mw-filters__search"
    assert_select ".mw-filters__search-icon"
    assert_select "input[name='q'].mw-filters__search-input"
    assert_select "select[name='kindergarten_year_id'].mw-filters__select"
    assert_select "select[name='group_id'].mw-filters__select"
    assert_select "select[name='status'].mw-filters__select"
  end

  test "F69 Titel-Suche filtert Events" do
    sign_in_as(@caretaker)
    get events_path(q: "Sommer")
    assert_response :success
    assert_match "Sommerfest", response.body
    assert_no_match "Zoo-Ausflug", response.body
  end

  test "F69 Status-Filter abgesagt zeigt nur abgesagte Events" do
    sign_in_as(@caretaker)
    get events_path(status: "cancelled")
    assert_response :success
    assert_match "Zoo-Ausflug", response.body
    assert_no_match "Sommerfest", response.body
  end

  test "F69 Status-Filter aktiv zeigt nur aktive Events" do
    sign_in_as(@caretaker)
    get events_path(status: "active")
    assert_response :success
    assert_match "Sommerfest", response.body
    assert_no_match "Zoo-Ausflug", response.body
  end

  test "F69 Reset-Link mit Count-Badge bei aktiven Filtern" do
    sign_in_as(@caretaker)
    get events_path(q: "Sommer", status: "active")
    assert_response :success
    assert_select ".mw-filters__reset"
    assert_select ".mw-filters__reset-count"
  end

  test "F69 Reset-Link verschwindet ohne aktive Filter (Default-Jahr ausgenommen)" do
    sign_in_as(@caretaker)
    get events_path
    assert_response :success
    assert_select ".mw-filters__reset", count: 0
  end
end
