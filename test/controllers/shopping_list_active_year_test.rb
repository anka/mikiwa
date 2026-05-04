# test/controllers/shopping_list_active_year_test.rb
require "test_helper"

# Tests that the active kindergarten year is automatically pre-filled
# when creating a shopping list – the core invariant: exactly one active year
# is always the right context for new records.
class ShoppingListActiveYearTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "betreuer_ay@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @year = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Aktiv-Bären")
  end

  # --- Happy path: form renders hidden field ---

  test "new action response includes hidden field with active kindergarten year id" do
    sign_in_as(@caretaker)

    get new_shopping_list_path

    assert_response :success
    assert_select "input[type='hidden'][name='shopping_list[kindergarten_year_id]'][value='#{@year.id}']"
  end

  # --- Happy path: create without explicit year param uses active year ---

  test "create without kindergarten_year_id in params assigns active year automatically" do
    sign_in_as(@caretaker)

    assert_difference "ShoppingList.count", 1 do
      post shopping_lists_path, params: {
        shopping_list: {
          title:      "Automatisches Jahr Test",
          event_date: "2026-06-15",
          group_id:   @group.id
        }
      }
    end

    list = ShoppingList.order(:created_at).last
    assert_equal @year.id, list.kindergarten_year_id
  end

  # --- Happy path: create with hidden field value works end-to-end ---

  test "create with kindergarten_year_id from hidden field saves successfully" do
    sign_in_as(@caretaker)

    assert_difference "ShoppingList.count", 1 do
      post shopping_lists_path, params: {
        shopping_list: {
          title:                 "Sommerfest Einkauf",
          event_date:            "2026-07-10",
          group_id:              @group.id,
          kindergarten_year_id:  @year.id
        }
      }
    end

    list = ShoppingList.order(:created_at).last
    assert_equal @year.id, list.kindergarten_year_id
    assert_redirected_to edit_shopping_list_path(list)
  end

  # --- Edge case: no active year ---

  test "new action succeeds even when no active year exists" do
    @year.update_columns(active: false)
    sign_in_as(@caretaker)

    get new_shopping_list_path

    assert_response :success
  end

  test "create without active year and without kindergarten_year_id renders validation error" do
    @year.update_columns(active: false)
    sign_in_as(@caretaker)

    assert_no_difference "ShoppingList.count" do
      post shopping_lists_path, params: {
        shopping_list: {
          title:      "Kein Jahr",
          event_date: "2026-06-15",
          group_id:   @group.id
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
