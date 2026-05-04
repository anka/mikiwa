require "test_helper"

class MealEntryTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Speiseplan-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff = User.create!(email: "staff_me@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")

    @entry = MealEntry.new(
      date: Date.new(2026, 5, 4),
      group: @group,
      kindergarten_year: @year,
      created_by: @staff
    )
    @entry.meal_courses.build(course_type: "main", name: "Nudeln mit Tomatensauce", dietary: "vegetarian")
  end

  test "valid meal entry with at least one course can be saved" do
    assert @entry.save, @entry.errors.full_messages.inspect
  end

  test "uses UUID primary key" do
    @entry.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @entry.id)
  end

  test "date is required" do
    @entry.date = nil
    assert_not @entry.valid?
    assert @entry.errors[:date].any?
  end

  test "F34 entry without any course is invalid" do
    @entry.meal_courses.clear
    assert_not @entry.valid?
    assert_includes @entry.errors[:base].join, "Mindestens eine Speise"
  end

  test "F34 entry with all courses blank is invalid" do
    @entry.meal_courses.clear
    @entry.assign_attributes(meal_courses_attributes: [
      { course_type: "starter", name: "" },
      { course_type: "main",    name: "" },
      { course_type: "dessert", name: "" },
      { course_type: "extra",   name: "" }
    ])
    assert_not @entry.valid?
    assert_includes @entry.errors[:base].join, "Mindestens eine Speise"
  end

  test "F34 nested attributes verwerfen leere Slots via reject_if" do
    new_entry = MealEntry.new(
      date: Date.new(2026, 5, 5),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [
        { course_type: "starter", name: "" },
        { course_type: "main",    name: "Spaghetti", dietary: "vegetarian" },
        { course_type: "dessert", name: "" },
        { course_type: "extra",   name: "" }
      ]
    )
    assert new_entry.save, new_entry.errors.full_messages.inspect
    assert_equal 1, new_entry.meal_courses.count
    assert_equal "main", new_entry.meal_courses.first.course_type
  end

  test "group is required" do
    @entry.group = nil
    assert_not @entry.valid?
    assert @entry.errors[:group].any?
  end

  test "notes is optional" do
    @entry.notes = nil
    assert @entry.valid?
  end

  test "date is unique per group" do
    @entry.save!
    duplicate = MealEntry.new(
      date: @entry.date, group: @group, kindergarten_year: @year, created_by: @staff
    )
    duplicate.meal_courses.build(course_type: "main", name: "Suppe")
    assert_not duplicate.valid?
    assert duplicate.errors[:date].any?
  end

  test "same date is allowed for different groups" do
    @entry.save!
    other_group = Group.create!(name: "Andere-Gruppe")
    other_entry = MealEntry.new(
      date: @entry.date, group: other_group, kindergarten_year: @year, created_by: @staff
    )
    other_entry.meal_courses.build(course_type: "main", name: "Suppe")
    assert other_entry.valid?
  end

  test "for_week scope returns entries for Mon-Fri of a week" do
    @entry.save!
    friday = MealEntry.create!(
      date: Date.new(2026, 5, 8),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [ { course_type: "main", name: "Pizza" } ]
    )
    weekend = MealEntry.create!(
      date: Date.new(2026, 5, 9),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [ { course_type: "main", name: "Brunch" } ]
    )
    results = MealEntry.for_week(Date.new(2026, 5, 6))
    assert_includes results, @entry
    assert_includes results, friday
    assert_not_includes results, weekend
  end

  test "for_week scope excludes entries from other weeks" do
    @entry.save!
    other_week = MealEntry.create!(
      date: Date.new(2026, 5, 11),
      group: @group, kindergarten_year: @year, created_by: @staff,
      meal_courses_attributes: [ { course_type: "main", name: "Reis" } ]
    )
    results = MealEntry.for_week(Date.new(2026, 5, 4))
    assert_includes results, @entry
    assert_not_includes results, other_week
  end

  # F34: courses_by_type liefert immer alle 4 Slots in fester Reihenfolge
  test "F34 courses_by_type liefert vier Slots in fester Reihenfolge" do
    @entry.save!
    types = @entry.courses_by_type.map(&:course_type)
    assert_equal MealCourse::COURSE_TYPES, types
  end

  test "F34 courses_by_type behält bestehende Courses" do
    @entry.save!
    main = @entry.meal_courses.first
    courses = @entry.courses_by_type
    assert_equal main, courses[1]
    assert courses[0].new_record?
    assert courses[2].new_record?
    assert courses[3].new_record?
  end

  test "F34 destroy entry destroys courses (dependent destroy)" do
    @entry.save!
    course_id = @entry.meal_courses.first.id
    @entry.destroy
    assert_not MealCourse.exists?(course_id)
  end
end
