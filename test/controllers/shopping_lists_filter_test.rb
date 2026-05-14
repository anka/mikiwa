require "test_helper"

class ShoppingListsFilterTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "f68_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @other     = User.create!(email: "f68_other@mikiwa.at",     password: "sicherespasswort1234", role: "caretaker")
    @year = KindergartenYear.create!(
      label: "F68-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "F68-Gruppe")

    @list_a = ShoppingList.create!(
      title: "Sommerfest Einkauf",
      event_date: Date.new(2026, 5, 14), group: @group,
      kindergarten_year: @year, created_by: @caretaker, assigned_to: @caretaker
    )
    @list_b = ShoppingList.create!(
      title: "Bastel-Material",
      event_date: Date.new(2026, 5, 14), group: @group,
      kindergarten_year: @year, created_by: @caretaker, assigned_to: @other
    )
  end

  test "F68 mw-filters Markup vorhanden" do
    sign_in_as(@caretaker)
    get shopping_lists_path
    assert_response :success
    assert_select "form.mw-filters"
    assert_select ".mw-filters__search"
    assert_select ".mw-filters__search-icon"
    assert_select "input[name='q'].mw-filters__search-input"
    assert_select "select[name='group_id'].mw-filters__select"
    assert_select "select[name='month'].mw-filters__select"
    assert_select "select[name='assigned_to_id'].mw-filters__select"
  end

  test "F68 Titel-Suche filtert Listen" do
    sign_in_as(@caretaker)
    get shopping_lists_path(q: "Sommer")
    assert_response :success
    assert_match "Sommerfest Einkauf", response.body
    assert_no_match "Bastel-Material", response.body
  end

  test "F68 Quick-Toggle 'Nur mir zugewiesen' reduziert auf assigned=me" do
    sign_in_as(@caretaker)
    get shopping_lists_path(assigned: "me")
    assert_response :success
    assert_match "Sommerfest Einkauf", response.body
    assert_no_match "Bastel-Material", response.body
  end

  test "F68 Reset-Link mit Count-Badge zaehlt auch assigned=me" do
    sign_in_as(@caretaker)
    get shopping_lists_path(q: "Sommer", assigned: "me")
    assert_response :success
    assert_select ".mw-filters__reset"
    assert_select ".mw-filters__reset-count"
  end

  test "F68 Reset-Link verschwindet ohne aktive Filter" do
    sign_in_as(@caretaker)
    get shopping_lists_path
    assert_response :success
    assert_select ".mw-filters__reset", count: 0
  end
end
