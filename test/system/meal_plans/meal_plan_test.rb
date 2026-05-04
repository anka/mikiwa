require "test_helper"

class MealPlanTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Meal-Gruppe")
    @caretaker = User.create!(email: "meal_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "meal_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @child = Child.create!(
      first_name: "MealKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @monday = Date.new(2026, 6, 1)
  end

  teardown do
    MealEntry.where(group: @group).destroy_all
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-049-S01: Betreuer legt Woche mit 5 Einträgen an
  test "TS-049 Betreuer legt 5 Tageseinträge für die Woche an" do
    sign_in_as(@caretaker)

    (0..4).each do |offset|
      assert_difference "MealEntry.count", 1 do
        post meal_entries_path, params: {
          meal_entry: {
            date: (@monday + offset.days).iso8601,
            group_id: @group.id,
            kindergarten_year_id: @year.id,
            meal_courses_attributes: {
              "0" => { course_type: "starter", name: "" },
              "1" => { course_type: "main",    name: "Menü #{offset + 1}", dietary: "standard" },
              "2" => { course_type: "dessert", name: "" },
              "3" => { course_type: "extra",   name: "" }
            }
          }
        }
      end
      assert_response :redirect
    end

    entries = MealEntry.for_week(@monday).where(group: @group)
    assert_equal 5, entries.count
  end

  # TS-049-S02: Eltern sehen Wochenansicht, kein Bearbeiten-Button
  test "TS-049 Elternteil sieht Speiseplan ohne Bearbeitungsoptionen" do
    (0..4).each do |offset|
      MealEntry.create!(
        date: @monday + offset.days,
        group: @group,
        kindergarten_year: @year,
        created_by: @caretaker,
        meal_courses_attributes: [
          { course_type: "main", name: "Menü #{offset + 1}" }
        ]
      )
    end

    sign_in_as(@parent)
    get meal_entries_path(week: @monday.iso8601)

    assert_response :success
    assert_match "Menü 1", response.body
    assert_no_match "Eintrag anlegen", response.body
  end
end
