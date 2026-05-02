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
      meal: "Nudeln mit Tomatensauce",
      group: @group,
      kindergarten_year: @year,
      created_by: @staff
    )
  end

  test "valid meal entry can be saved" do
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

  test "meal is required" do
    @entry.meal = nil
    assert_not @entry.valid?
    assert @entry.errors[:meal].any?
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
      date: @entry.date, meal: "Suppe",
      group: @group, kindergarten_year: @year, created_by: @staff
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:date].any?
  end

  test "same date is allowed for different groups" do
    @entry.save!
    other_group = Group.create!(name: "Andere-Gruppe")
    other_entry = MealEntry.new(
      date: @entry.date, meal: "Suppe",
      group: other_group, kindergarten_year: @year, created_by: @staff
    )
    assert other_entry.valid?
  end

  test "for_week scope returns entries for Mon-Fri of a week" do
    @entry.save!
    friday = MealEntry.create!(
      date: Date.new(2026, 5, 8),
      meal: "Pizza",
      group: @group, kindergarten_year: @year, created_by: @staff
    )
    weekend = MealEntry.create!(
      date: Date.new(2026, 5, 9),
      meal: "Brunch",
      group: @group, kindergarten_year: @year, created_by: @staff
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
      meal: "Reis",
      group: @group, kindergarten_year: @year, created_by: @staff
    )
    results = MealEntry.for_week(Date.new(2026, 5, 4))
    assert_includes results, @entry
    assert_not_includes results, other_week
  end
end
