require "test_helper"

class MealCourseTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Course-Gruppe")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff = User.create!(email: "course_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")

    @entry = MealEntry.create!(
      date: Date.new(2026, 5, 4),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [ { course_type: "main", name: "Anker-Hauptspeise", position: 1 } ]
    )
  end

  test "F34 valid course requires course_type, name, dietary" do
    course = @entry.meal_courses.build(course_type: "starter", name: "Suppe", dietary: "vegetarian")
    assert course.valid?
  end

  test "F34 name is required" do
    course = @entry.meal_courses.build(course_type: "starter", name: "", dietary: "standard")
    assert_not course.valid?
    assert course.errors[:name].any?
  end

  test "F34 course_type must be one of the enum values" do
    course = @entry.meal_courses.build(course_type: "snack", name: "X")
    assert_not course.valid?
    assert course.errors[:course_type].any?
  end

  test "F34 dietary must be standard, vegetarian or vegan" do
    course = @entry.meal_courses.build(course_type: "dessert", name: "X", dietary: "kosher")
    assert_not course.valid?
    assert course.errors[:dietary].any?
  end

  test "F34 dietary defaults to standard" do
    course = @entry.meal_courses.build(course_type: "extra", name: "Brot")
    assert_equal "standard", course.dietary
    assert course.valid?
  end

  test "F34 same course_type cannot exist twice in one MealEntry" do
    duplicate_main = @entry.meal_courses.build(course_type: "main", name: "Zweite Hauptspeise")
    assert_not duplicate_main.valid?
    assert duplicate_main.errors[:course_type].any?
  end

  test "F34 same course_type kann in verschiedenen MealEntries vorkommen" do
    other_entry = MealEntry.create!(
      date: Date.new(2026, 5, 5),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [ { course_type: "main", name: "Andere Hauptspeise" } ]
    )
    assert other_entry.persisted?
    assert_equal "main", other_entry.meal_courses.first.course_type
  end

  test "F34 ordered scope sortiert nach position" do
    @entry.meal_courses.create!(course_type: "starter", name: "Suppe", position: 0)
    @entry.meal_courses.create!(course_type: "dessert", name: "Pudding", position: 2)
    @entry.meal_courses.create!(course_type: "extra",   name: "Brot",    position: 3)

    types = @entry.meal_courses.ordered.pluck(:course_type)
    assert_equal %w[starter main dessert extra], types
  end

  test "F34 label gibt deutsche Bezeichnung zurück" do
    course = @entry.meal_courses.build(course_type: "starter", name: "Suppe")
    assert_equal "Vorspeise", course.label
  end

  test "F34 dietary_label gibt deutsche Bezeichnung zurück" do
    course = @entry.meal_courses.build(course_type: "main", name: "X", dietary: "vegan")
    assert_equal "Vegan", course.dietary_label
  end

  test "F34 dietary predicates funktionieren" do
    course = @entry.meal_courses.build(course_type: "main", name: "X", dietary: "vegan")
    assert course.vegan?
    assert_not course.vegetarian?
    assert_not course.standard?
  end
end
