require "test_helper"

class ShoppingListSystemTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "SL-System-Gruppe")
    @caretaker = User.create!(email: "sl_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "sl_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child = Child.create!(
      first_name: "SL-Kind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = ShoppingList.create!(
      title: "Waldtag-SL", event_date: Date.new(2026, 6, 20),
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
    @item_open   = @list.shopping_items.create!(name: "Offener Artikel")
    @item_done1  = @list.shopping_items.create!(name: "Erledigter Artikel 1")
    @item_done2  = @list.shopping_items.create!(name: "Erledigter Artikel 2")
    @item_done1.complete!(@caretaker)
    @item_done2.complete!(@caretaker)
  end

  teardown do
    @list.shopping_items.destroy_all
    @list.destroy!
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-042-S01: Elternteil markiert Einkaufseintrag als erledigt
  test "TS-042 Elternteil markiert Eintrag als erledigt" do
    sign_in_as(@parent)

    patch complete_shopping_list_shopping_item_path(@list, @item_open)
    assert_response :redirect

    @item_open.reload
    assert @item_open.done?
    assert_equal @parent.id, @item_open.completed_by_id
  end

  # TS-042-S02: Filter zeigt nur offene Einträge
  test "TS-042 Filter 'nur offen' zeigt nur offene Einträge" do
    sign_in_as(@parent)

    get shopping_list_path(@list), params: { filter: "open" }
    assert_response :success
    assert_match "Offener Artikel",     response.body
    assert_no_match "Erledigter Artikel 1", response.body
    assert_no_match "Erledigter Artikel 2", response.body
  end

  # TS-042-S03: Erledigt rückgängig machen
  test "TS-042 Erledigt-Status kann aufgehoben werden" do
    sign_in_as(@parent)

    patch uncomplete_shopping_list_shopping_item_path(@list, @item_done1)
    assert_response :redirect

    @item_done1.reload
    assert_not @item_done1.done?
  end
end
