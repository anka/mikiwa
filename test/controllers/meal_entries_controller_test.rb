require "test_helper"

class MealEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group   = Group.create!(name: "Speiseplan-Test-Bären")
    @year    = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_mec@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_mec@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child  = Child.create!(
      first_name: "Hanna", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @entry = MealEntry.create!(
      date: Date.new(2026, 5, 4),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [
        { course_type: "main", name: "Nudeln", dietary: "vegetarian", position: 1 }
      ]
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

  test "F34 new form zeigt alle vier Course-Slots" do
    sign_in_as(@staff)
    get new_meal_entry_path
    assert_response :success
    %w[Vorspeise Hauptspeise Nachspeise Zusatzspeise].each do |label|
      assert_match label, response.body, "Slot #{label} muss im Form sein"
    end
    # Text-Inputs für alle vier Course-Names
    assert_match(/name="meal_entry\[meal_courses_attributes\]\[0\]\[name\]"/, response.body)
    assert_match(/name="meal_entry\[meal_courses_attributes\]\[3\]\[name\]"/, response.body)
  end

  test "parent cannot open new meal entry form" do
    sign_in_as(@parent)
    get new_meal_entry_path
    assert_response :forbidden
  end

  test "F34 staff can create meal entry mit nur Hauptspeise (andere leer)" do
    sign_in_as(@staff)
    assert_difference "MealEntry.count", 1 do
      assert_difference "MealCourse.count", 1 do
        post meal_entries_path, params: {
          meal_entry: {
            date: "2026-05-11",
            group_id: @group.id,
            kindergarten_year_id: @year.id,
            meal_courses_attributes: {
              "0" => { course_type: "starter", name: "",         dietary: "standard",   position: 0 },
              "1" => { course_type: "main",    name: "Spaghetti",dietary: "vegetarian", position: 1 },
              "2" => { course_type: "dessert", name: "",         dietary: "standard",   position: 2 },
              "3" => { course_type: "extra",   name: "",         dietary: "standard",   position: 3 }
            }
          }
        }
      end
    end
    assert_redirected_to meal_entries_path(week: "2026-05-11")
    new_entry = MealEntry.find_by(date: "2026-05-11", group: @group)
    assert_equal 1, new_entry.meal_courses.count
    course = new_entry.meal_courses.first
    assert_equal "main", course.course_type
    assert_equal "vegetarian", course.dietary
  end

  test "F34 staff can create meal entry mit allen vier Slots" do
    sign_in_as(@staff)
    post meal_entries_path, params: {
      meal_entry: {
        date: "2026-05-12",
        group_id: @group.id,
        kindergarten_year_id: @year.id,
        meal_courses_attributes: {
          "0" => { course_type: "starter", name: "Suppe",       dietary: "vegan",      position: 0 },
          "1" => { course_type: "main",    name: "Spaghetti",   dietary: "vegetarian", position: 1 },
          "2" => { course_type: "dessert", name: "Apfelmus",    dietary: "vegan",      position: 2 },
          "3" => { course_type: "extra",   name: "Brot",        dietary: "standard",   position: 3 }
        }
      }
    }
    assert_redirected_to meal_entries_path(week: "2026-05-12")
    new_entry = MealEntry.find_by(date: "2026-05-12", group: @group)
    assert_equal 4, new_entry.meal_courses.count
  end

  test "F34 create mit allen vier Slots leer schlägt fehl" do
    sign_in_as(@staff)
    assert_no_difference "MealEntry.count" do
      post meal_entries_path, params: {
        meal_entry: {
          date: "2026-05-13",
          group_id: @group.id,
          kindergarten_year_id: @year.id,
          meal_courses_attributes: {
            "0" => { course_type: "starter", name: "" },
            "1" => { course_type: "main",    name: "" },
            "2" => { course_type: "dessert", name: "" },
            "3" => { course_type: "extra",   name: "" }
          }
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/Mindestens eine Speise/i, response.body)
  end

  test "parent cannot create meal entry" do
    sign_in_as(@parent)
    assert_no_difference "MealEntry.count" do
      post meal_entries_path, params: {
        meal_entry: {
          date: "2026-05-11",
          group_id: @group.id,
          kindergarten_year_id: @year.id,
          meal_courses_attributes: { "0" => { course_type: "main", name: "Versuch" } }
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
          group_id: @group.id,
          kindergarten_year_id: @year.id,
          meal_courses_attributes: { "0" => { course_type: "main", name: "Suppe" } }
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

  test "F34 edit zeigt alle vier Slots, vorhandener Course vorbefüllt" do
    sign_in_as(@staff)
    get edit_meal_entry_path(@entry)
    assert_response :success
    assert_match "Vorspeise", response.body
    assert_match "Hauptspeise", response.body
    assert_match "Nachspeise", response.body
    assert_match "Zusatzspeise", response.body
    assert_match "Nudeln", response.body  # bestehender Hauptspeisen-Wert
  end

  test "parent cannot edit meal entry" do
    sign_in_as(@parent)
    get edit_meal_entry_path(@entry)
    assert_response :forbidden
  end

  # BF-008: Dietary-Radio-Pill nicht reaktiv – Fix-Verifizierung
  test "BF-008 Edit-Form rendert keine hardcoded mw-radio-pill--active-Klasse" do
    sign_in_as(@staff)
    get edit_meal_entry_path(@entry)
    assert_response :success
    refute_match(/mw-radio-pill--active/, response.body,
                 "Hardcoded --active-Klasse muss entfernt sein; Active-State steuert :has(:checked)")
  end

  test "BF-008 Edit-Form markiert persistierten Dietary-Wert als checked" do
    sign_in_as(@staff)
    get edit_meal_entry_path(@entry)
    assert_response :success
    assert_select 'input[type="radio"][name*="dietary"][value="vegetarian"][checked="checked"]'
  end

  test "F34 staff can update meal entry und neue Courses ergänzen" do
    sign_in_as(@staff)
    main_id = @entry.meal_courses.first.id
    patch meal_entry_path(@entry), params: {
      meal_entry: {
        date: @entry.date,
        group_id: @group.id,
        kindergarten_year_id: @year.id,
        meal_courses_attributes: {
          "0" => { course_type: "starter", name: "Tomatensuppe", dietary: "vegan",      position: 0 },
          "1" => { id: main_id, course_type: "main", name: "Risotto", dietary: "vegetarian", position: 1 },
          "2" => { course_type: "dessert", name: "",             dietary: "standard",   position: 2 },
          "3" => { course_type: "extra",   name: "",             dietary: "standard",   position: 3 }
        }
      }
    }
    assert_redirected_to meal_entries_path(week: @entry.date.iso8601)
    @entry.reload
    types = @entry.meal_courses.ordered.pluck(:course_type)
    assert_equal %w[starter main], types
    assert_equal "Risotto", @entry.meal_courses.find(main_id).name
  end

  # --- destroy ---

  test "staff can delete meal entry" do
    sign_in_as(@staff)
    assert_difference "MealEntry.count", -1 do
      delete meal_entry_path(@entry)
    end
    assert_redirected_to meal_entries_path(week: @entry.date.iso8601)
  end

  test "F34 destroy entry cascades to courses" do
    sign_in_as(@staff)
    course_id = @entry.meal_courses.first.id
    delete meal_entry_path(@entry)
    assert_not MealCourse.exists?(course_id)
  end

  test "parent cannot delete meal entry" do
    sign_in_as(@parent)
    assert_no_difference "MealEntry.count" do
      delete meal_entry_path(@entry)
    end
    assert_response :forbidden
  end

  # --- F34: Index-Layout ---

  test "F34 Index zeigt Course-Sub-Reihen pro Gruppe" do
    sign_in_as(@staff)
    get meal_entries_path, params: { week: "2026-05-04" }
    assert_response :success
    %w[Vorspeise Hauptspeise Nachspeise Zusatzspeise].each do |label|
      assert_match label, response.body
    end
    # Hauptspeise-Wert in der Mo-Spalte
    assert_match "Nudeln", response.body
  end

  test "F34 Index zeigt Diät-Icon für vegetarisches Hauptgericht" do
    sign_in_as(@staff)
    get meal_entries_path, params: { week: "2026-05-04" }
    assert_response :success
    assert_match(/mw-diet-icon mw-diet-icon--vegetarian|title="Vegetarisch"/, response.body)
  end

  test "F34 Index zeigt Notiz dezent wenn vorhanden" do
    @entry.update!(notes: "Spezial-Tag")
    sign_in_as(@staff)
    get meal_entries_path, params: { week: "2026-05-04" }
    assert_response :success
    assert_match "Spezial-Tag", response.body
  end

  # --- F33: Druckansicht (existierend, an neue Struktur angepasst) ---

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
    assert_match "/meal_entries/print?group_id=#{@group.id}", response.body
    assert_match "week=2026-05-04", response.body
    assert_match "Drucken", response.body
  end

  # --- F34: Druck zeigt Courses + Diät ---

  test "F34 Druck zeigt nur befüllte Course-Slots, keine leeren" do
    @entry.meal_courses.create!(course_type: "dessert", name: "Apfelmus", dietary: "vegan", position: 2)

    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    assert_match "Hauptspeise", response.body
    assert_match "Nachspeise", response.body
    assert_no_match(/Vorspeise/, response.body, "Leere Vorspeise soll im Druck nicht erscheinen")
    assert_no_match(/Zusatzspeise/, response.body, "Leere Zusatzspeise soll im Druck nicht erscheinen")
  end

  test "F34 Druck zeigt Diät-Icon für vegane Speise" do
    @entry.meal_courses.create!(course_type: "dessert", name: "Apfelmus", dietary: "vegan", position: 2)

    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    assert_match(/mw-diet-icon mw-diet-icon--vegan|title="Vegan"/, response.body)
  end

  test "F34 Druck enthält Legende für Vegetarisch- und Vegan-Icons" do
    sign_in_as(@staff)
    get print_meal_entries_path, params: { group_id: @group.id, week: "2026-05-04" }
    assert_response :success
    legend_match = response.body.match(/<div[^>]*class="mw-print-legend"[^>]*>(.*?)<\/div>/m)
    assert legend_match, "Legende-Section muss gerendert werden"
    legend = legend_match[1]
    assert_match "Vegetarisch", legend
    assert_match "Vegan", legend
    assert_match(/mw-diet-icon--vegetarian/, legend)
    assert_match(/mw-diet-icon--vegan/, legend)
  end
end
