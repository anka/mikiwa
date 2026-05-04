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

  # --- print (F33: Speiseplan pro Gruppe drucken) ---

  test "F33 staff kann Druck-Ansicht öffnen" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    assert_match @group.name, response.body
    assert_match "Nudeln", response.body
  end

  test "F33 Druck-Ansicht zeigt alle 5 Wochentage Mo-Fr" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    %w[Montag Dienstag Mittwoch Donnerstag Freitag].each do |day|
      assert_match day, response.body, "Wochentag #{day} muss im Druck-Layout vorkommen"
    end
  end

  test "F33 Druck-Ansicht zeigt 'Noch nicht geplant' für leere Tage" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    assert_match(/Noch nicht geplant/i, response.body)
  end

  test "F33 Druck-Ansicht löst window.print() automatisch aus" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    assert_match(/window\.print\(\)/, response.body)
  end

  test "F33 Druck-Ansicht nutzt minimales print-Layout (kein Sidebar/Topbar)" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    assert_no_match(/mw-sidebar/, response.body, "Sidebar darf im Druck-Layout nicht erscheinen")
    assert_no_match(/mw-mobile-nav/, response.body, "Mobile-Nav darf im Druck-Layout nicht erscheinen")
    assert_no_match(/mw-app-topbar/, response.body, "Topbar darf im Druck-Layout nicht erscheinen")
  end

  test "F33 Eltern dürfen Druck für eigene Gruppe öffnen" do
    sign_in_as(@parent)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
  end

  test "F33 Eltern bekommt 403 für fremde Gruppe" do
    sign_in_as(@parent)
    fremde_gruppe = Group.create!(name: "Fremd-Gruppe")
    get print_meal_entries_path, params: { group_id: fremde_gruppe.id, week: "2026-05-04" }
    assert_response :forbidden
  end

  test "F33 Druck ohne group_id → 404" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { week: "2026-05-04" }
    assert_response :not_found
  end

  test "F33 Druck mit unbekannter group_id → 404" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: "no-such-id", week: "2026-05-04" }
    assert_response :not_found
  end

  test "F33 Index zeigt Druck-Button pro Gruppe mit korrekten Parametern" do
    sign_in_as(@staff)
    get meal_entries_path, params: { week: "2026-05-04" }
    assert_response :success
    # URL-Parameter werden HTML-escaped (& → &amp;), daher beide Teile separat prüfen
    assert_match "/meal_entries/print?group_id=#{@group.id}", response.body
    assert_match "week=2026-05-04", response.body
    assert_match "Drucken", response.body
  end
end
