require "test_helper"

class MealEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group   = Group.create!(name: "Speiseplan-Test-Bären")
    @year    = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_mec@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_mec@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @child  = Child.create!(
      first_name: "Hanna", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @entry = MealEntry.create!(
      date: Date.new(2026, 5, 4),
      meal: "Nudeln",
      group: @group,
      kindergarten_year: @year,
      created_by: @staff
    )
  end

  # --- index ---

  test "staff can access weekly meal plan" do
    sign_in_as(@staff)
    get meal_entries_path
    assert_response :success
  end

  test "parent can view meal plan (read-only)" do
    sign_in_as(@parent)
    get meal_entries_path
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    get meal_entries_path
    assert_response :redirect
  end

  test "index accepts week param for navigation" do
    sign_in_as(@staff)
    get meal_entries_path, params: { week: "2026-05-11" }
    assert_response :success
  end

  # --- new / create ---

  test "staff can open new meal entry form" do
    sign_in_as(@staff)
    get new_meal_entry_path
    assert_response :success
  end

  test "parent cannot open new meal entry form" do
    sign_in_as(@parent)
    get new_meal_entry_path
    assert_response :forbidden
  end

  test "staff can create meal entry" do
    sign_in_as(@staff)
    assert_difference "MealEntry.count", 1 do
      post meal_entries_path, params: {
        meal_entry: {
          date: "2026-05-11",
          meal: "Gemüsesuppe",
          group_id: @group.id,
          kindergarten_year_id: @year.id
        }
      }
    end
    assert_redirected_to meal_entries_path(week: "2026-05-11")
  end

  test "parent cannot create meal entry" do
    sign_in_as(@parent)
    assert_no_difference "MealEntry.count" do
      post meal_entries_path, params: {
        meal_entry: {
          date: "2026-05-11",
          meal: "Versuch",
          group_id: @group.id,
          kindergarten_year_id: @year.id
        }
      }
    end
    assert_response :forbidden
  end

  test "create renders new on validation error" do
    sign_in_as(@staff)
    assert_no_difference "MealEntry.count" do
      post meal_entries_path, params: {
        meal_entry: {
          date: "",
          meal: "Suppe",
          group_id: @group.id,
          kindergarten_year_id: @year.id
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- edit / update ---

  test "staff can edit meal entry" do
    sign_in_as(@staff)
    get edit_meal_entry_path(@entry)
    assert_response :success
  end

  test "parent cannot edit meal entry" do
    sign_in_as(@parent)
    get edit_meal_entry_path(@entry)
    assert_response :forbidden
  end

  test "staff can update meal entry" do
    sign_in_as(@staff)
    patch meal_entry_path(@entry), params: {
      meal_entry: { meal: "Überarbeitetes Gericht" }
    }
    assert_equal "Überarbeitetes Gericht", @entry.reload.meal
    assert_redirected_to meal_entries_path(week: @entry.date.iso8601)
  end

  # --- destroy ---

  test "staff can delete meal entry" do
    sign_in_as(@staff)
    assert_difference "MealEntry.count", -1 do
      delete meal_entry_path(@entry)
    end
    assert_redirected_to meal_entries_path(week: @entry.date.iso8601)
  end

  test "parent cannot delete meal entry" do
    sign_in_as(@parent)
    assert_no_difference "MealEntry.count" do
      delete meal_entry_path(@entry)
    end
    assert_response :forbidden
  end
end
