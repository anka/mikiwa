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

  # TS-066-S01: 5 Einträge anlegen → alle sichtbar; Menge ist optional
  test "TS-066 Betreuer legt Einkaufsliste mit 5 Einträgen an" do
    sign_in_as(@caretaker)

    items_attrs = {
      "0" => { name: "Mehl", quantity: "500g" },
      "1" => { name: "Zucker", quantity: "" },
      "2" => { name: "Eier", quantity: "12 Stück" },
      "3" => { name: "Milch", quantity: "" },
      "4" => { name: "Butter", quantity: "250g" }
    }

    post shopping_lists_path, params: {
      shopping_list: {
        title: "Backtag-Liste",
        event_date: "2026-05-20",
        group_id: @group.id,
        kindergarten_year_id: @year.id,
        shopping_items_attributes: items_attrs
      }
    }
    assert_response :redirect

    list = ShoppingList.find_by!(title: "Backtag-Liste")
    assert_equal 5, list.shopping_items.count, "Liste muss 5 Einträge enthalten"

    get shopping_list_path(list)
    assert_response :success
    %w[Mehl Zucker Eier Milch Butter].each do |item_name|
      assert_match item_name, response.body, "#{item_name} muss in der Liste sichtbar sein"
    end
  end
end
