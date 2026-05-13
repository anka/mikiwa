require "test_helper"

class ShoppingListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_slc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_slc@mikiwa.at",   password: SecureRandom.hex(20),   role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Shop-Bären")
    @group_loewen = Group.create!(name: "Shop-Löwen")

    @child = Child.create!(
      first_name: "Jonas", last_name: "Bauer",
      date_of_birth: Date.new(2021, 9, 1),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = ShoppingList.create!(
      title: "Waldtag-Einkauf", event_date: Date.new(2026, 6, 20),
      group: @group_baeren, kindergarten_year: @year, created_by: @caretaker
    )
    @item = @list.shopping_items.create!(name: "2 kg Mehl")

    @other_list = ShoppingList.create!(
      title: "Löwen-Einkauf", event_date: Date.new(2026, 6, 21),
      group: @group_loewen, kindergarten_year: @year, created_by: @caretaker
    )
  end

  test "parent sees only own group lists" do
    sign_in_as(@parent)
    get shopping_lists_path
    assert_response :success
    assert_match "Waldtag-Einkauf", response.body
    assert_no_match "Löwen-Einkauf", response.body
  end

  test "caretaker can create shopping list" do
    sign_in_as(@caretaker)
    assert_difference "ShoppingList.count", 1 do
      post shopping_lists_path, params: {
        shopping_list: {
          title: "Sommerfest-Einkauf",
          event_date: "2026-07-10",
          group_id: @group_baeren.id,
          kindergarten_year_id: @year.id,
          shopping_items_attributes: {
            "0" => { name: "Wasser", quantity: "5 l" },
            "1" => { name: "Äpfel", quantity: "3 kg" }
          }
        }
      }
    end
  end

  test "parent cannot create list (403)" do
    sign_in_as(@parent)
    post shopping_lists_path, params: {
      shopping_list: { title: "X", event_date: "2026-07-10", group_id: @group_baeren.id }
    }
    assert_response :forbidden
  end

  test "parent can mark item as done (Erledigt markieren)" do
    sign_in_as(@parent)
    patch complete_shopping_list_shopping_item_path(@list, @item)
    assert_redirected_to shopping_list_path(@list)
    @item.reload
    assert @item.done?
    assert_equal @parent.id, @item.completed_by_id
  end

  test "done status is visible to all participants" do
    @item.complete!(@caretaker)
    sign_in_as(@parent)
    get shopping_list_path(@list)
    assert_response :success
    assert_match @caretaker.full_name.presence || @caretaker.email, response.body
  end

  test "parent can undo done status (Erledigt rückgängig)" do
    @item.complete!(@parent)
    sign_in_as(@parent)
    patch uncomplete_shopping_list_shopping_item_path(@list, @item)
    assert_redirected_to shopping_list_path(@list)
    assert_not @item.reload.done?
  end

  # F25: Einkaufsliste optional einer Gruppe zuordnen
  test "F25 Caretaker kann Liste ohne Gruppe (Kindergarten-weit) anlegen" do
    sign_in_as(@caretaker)
    assert_difference "ShoppingList.count", 1 do
      post shopping_lists_path, params: {
        shopping_list: {
          title: "Kindergarten-Einkauf",
          event_date: "2026-07-15",
          group_id: "",
          kindergarten_year_id: @year.id
        }
      }
    end
    assert_nil ShoppingList.find_by(title: "Kindergarten-Einkauf").group_id
  end

  test "F25 Index zeigt Badge 'Kindergarten' für Liste ohne Gruppe" do
    sign_in_as(@caretaker)
    ShoppingList.create!(
      title: "KG-Einkauf", event_date: Date.new(2026, 6, 22),
      group: nil, kindergarten_year: @year, created_by: @caretaker
    )
    get shopping_lists_path
    assert_response :success
    assert_match(/Kindergarten/, response.body)
  end

  test "F25 Form bietet Option 'Gesamter Kindergarten' (Blank-Option)" do
    sign_in_as(@caretaker)
    get new_shopping_list_path
    assert_response :success
    assert_match(/Gesamter Kindergarten/i, response.body)
  end

  test "F25 Eltern sieht KEINE Liste ohne Gruppe (staff-intern)" do
    sign_in_as(@parent)
    ShoppingList.create!(
      title: "Staff-only-KG-Einkauf", event_date: Date.new(2026, 6, 22),
      group: nil, kindergarten_year: @year, created_by: @caretaker
    )
    get shopping_lists_path
    assert_response :success
    assert_no_match(/Staff-only-KG-Einkauf/, response.body)
  end

  test "F25 Staff sieht Liste ohne Gruppe" do
    sign_in_as(@caretaker)
    ShoppingList.create!(
      title: "Staff-KG-Einkauf", event_date: Date.new(2026, 6, 22),
      group: nil, kindergarten_year: @year, created_by: @caretaker
    )
    get shopping_lists_path
    assert_response :success
    assert_match(/Staff-KG-Einkauf/, response.body)
  end

  # F26: Einkaufsliste optional einem Elternteil zuordnen
  test "F26 Caretaker kann Liste mit assigned_to anlegen" do
    sign_in_as(@caretaker)
    assert_difference "ShoppingList.count", 1 do
      post shopping_lists_path, params: {
        shopping_list: {
          title: "Eltern-Aufgabe",
          event_date: "2026-07-15",
          group_id: @group_baeren.id,
          kindergarten_year_id: @year.id,
          assigned_to_id: @parent.id
        }
      }
    end
    assert_equal @parent, ShoppingList.find_by(title: "Eltern-Aufgabe").assigned_to
  end

  test "F26 Index zeigt 'Nicht zugewiesen' bei fehlendem assigned_to" do
    sign_in_as(@caretaker)
    get shopping_lists_path
    assert_response :success
    assert_match(/Nicht zugewiesen/i, response.body)
  end

  test "F26 Index zeigt Verantwortlichen-Namen" do
    sign_in_as(@caretaker)
    @list.update!(assigned_to: @parent)
    get shopping_lists_path
    assert_response :success
    assert_match @parent.full_name, response.body
  end

  test "F26 Form bietet assigned_to-Auswahl" do
    sign_in_as(@caretaker)
    get edit_shopping_list_path(@list)
    assert_response :success
    assert_match(/name="shopping_list\[assigned_to_id\]"/, response.body)
  end

  test "F26 Pundit-Scope: Eltern sieht KEINE KG-weite Liste" do
    sign_in_as(@parent)
    ShoppingList.create!(
      title: "Eltern-Sicht-KG", event_date: Date.new(2026, 6, 22),
      group: nil, kindergarten_year: @year, created_by: @caretaker,
      assigned_to: @parent
    )
    get shopping_lists_path
    assert_response :success
    assert_no_match(/Eltern-Sicht-KG/, response.body)
  end

  test "F26 Filter 'Nur mir zugewiesen' beschränkt Index" do
    sign_in_as(@caretaker)
    @list.update!(assigned_to: @caretaker)
    get shopping_lists_path, params: { assigned: "me" }
    assert_response :success
    assert_match @list.title, response.body
    assert_no_match @other_list.title, response.body
  end

  # F48: Bezugstag → Einkaufstag
  test "F48 New-Form Label heißt 'Einkaufstag' (nicht 'Bezugstag')" do
    sign_in_as(@caretaker)
    get new_shopping_list_path
    assert_response :success
    assert_match(/Einkaufstag/, response.body)
    assert_no_match(/Bezugstag/, response.body)
  end

  # BF-005: ShoppingItem-Eingabe — Fokus-Bug nach Append
  test "BF-005 Create-Response trägt Marker zum Re-Fokus auf das neue Form" do
    sign_in_as(@caretaker)
    post shopping_list_shopping_items_path(@list),
         params: { shopping_item: { name: "Brot" } },
         as: :turbo_stream
    assert_response :success
    assert_match(/data-focus-on-connect="true"/, response.body,
                 "Turbo-Stream-Response muss data-focus-on-connect='true' auf dem neuen Form-Element setzen")
  end
end
