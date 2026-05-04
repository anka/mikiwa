require "test_helper"

class ShoppingListCreateTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Einkauf-Gruppe")
    @caretaker = User.create!(
      email: "shop_create@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
  end

  teardown do
    ShoppingList.joins(:group).where(groups: { name: "Einkauf-Gruppe" }).each do |l|
      l.shopping_items.destroy_all
      l.destroy!
    end
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-066-S01: Liste anlegen + 5 Einträge per Item-Endpoint hinzufügen → alle sichtbar
  test "TS-066 Betreuer legt Einkaufsliste mit 5 Einträgen an" do
    sign_in_as(@caretaker)

    post shopping_lists_path, params: {
      shopping_list: {
        title: "Backtag-Liste",
        event_date: "2026-05-20",
        group_id: @group.id,
        kindergarten_year_id: @year.id
      }
    }
    assert_response :redirect
    list = ShoppingList.find_by!(title: "Backtag-Liste")
    assert_redirected_to edit_shopping_list_path(list)

    [
      { name: "Mehl",   quantity: "500g" },
      { name: "Zucker", quantity: "" },
      { name: "Eier",   quantity: "12 Stück" },
      { name: "Milch",  quantity: "" },
      { name: "Butter", quantity: "250g" }
    ].each do |attrs|
      post shopping_list_shopping_items_path(list), params: { shopping_item: attrs }, as: :turbo_stream
      assert_response :success, "POST /shopping_items für #{attrs[:name]} muss 200 sein"
    end

    assert_equal 5, list.shopping_items.count, "Liste muss 5 Einträge enthalten"

    get shopping_list_path(list)
    assert_response :success
    %w[Mehl Zucker Eier Milch Butter].each do |item_name|
      assert_match item_name, response.body, "#{item_name} muss in der Liste sichtbar sein"
    end
  end
end
