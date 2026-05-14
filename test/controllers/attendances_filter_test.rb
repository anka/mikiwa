require "test_helper"

class AttendancesFilterTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "F66-Gruppe")
    @year  = KindergartenYear.create!(
      label: "F66-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f66_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @max  = Child.create!(first_name: "Max",  last_name: "Mustermann", date_of_birth: Date.new(2021, 1, 1),
                          group: @group, kindergarten_year: @year, photo_consent: true)
    @lisa = Child.create!(first_name: "Lisa", last_name: "Stern",      date_of_birth: Date.new(2021, 1, 1),
                          group: @group, kindergarten_year: @year, photo_consent: true)
  end

  test "F66 Filter-Bar nutzt mw-filters Markup" do
    sign_in_as(@caretaker)
    get attendances_path(date: "2026-05-14", group_id: @group.id)
    assert_response :success
    assert_select "form.mw-filters"
    assert_select ".mw-filters__row"
    assert_select ".mw-filters__search"
    assert_select ".mw-filters__search-icon"
    assert_select "input[name='q'].mw-filters__search-input"
    assert_select "input[type='date'][name='date']"
    assert_select "select[name='group_id'].mw-filters__select"
  end

  test "F66 Kind-Suche filtert Tabelle" do
    sign_in_as(@caretaker)
    get attendances_path(date: "2026-05-14", group_id: @group.id, q: "Max")
    assert_response :success
    assert_match "Max Mustermann", response.body
    assert_no_match "Lisa Stern", response.body
  end

  test "F66 Reset-Link mit Count-Badge nur wenn Filter aktiv" do
    sign_in_as(@caretaker)
    # Mit Suche aktiv → Reset-Link sichtbar mit Count
    get attendances_path(date: "2026-05-14", group_id: @group.id, q: "Max")
    assert_response :success
    assert_select ".mw-filters__reset"
    assert_select ".mw-filters__reset-count", text: /1|2/
  end

  test "F66 Reset-Link verschwindet ohne aktive Filter" do
    sign_in_as(@caretaker)
    # Default-Status: heute, keine Gruppe, keine Suche → kein Reset-Link
    get attendances_path
    assert_response :success
    assert_select ".mw-filters__reset", count: 0
  end

  test "F66 Default-Datum ist heute" do
    sign_in_as(@caretaker)
    get attendances_path(group_id: @group.id)
    assert_response :success
    assert_select "input[type='date'][name='date'][value=?]", Date.current.to_fs(:iso8601)
  end
end
