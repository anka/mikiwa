require "test_helper"

class MealEntryYearRolloverTest < ActiveSupport::TestCase
  setup do
    @year_2526 = KindergartenYear.create!(
      label: "2025/26-MERO", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @year_2627 = KindergartenYear.create!(
      label: "2026/27-MERO", start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 7, 31), active: false
    )
    @group = Group.create!(name: "RO-Gruppe")
    @staff = User.create!(email: "ro_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")

    @child = Child.create!(
      first_name: "RolloverKind", last_name: "Test",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year_2526, photo_consent: true
    )

    MealEntry.create!(
      date: Date.new(2025, 10, 1),
      group: @group, kindergarten_year: @year_2526, created_by: @staff,
      meal_courses_attributes: [ { course_type: "main", name: "Menü 1" } ]
    )
  end

  teardown do
    Child.where(last_name: "Test", first_name: "RolloverKind").each do |c|
      c.emergency_contacts.destroy_all
      c.parent_children.destroy_all
      c.destroy!
    end
    MealEntry.where(kindergarten_year: [ @year_2526, @year_2627 ]).destroy_all
    @staff.destroy!
    @group.destroy!
    @year_2627.destroy!
    @year_2526.destroy!
  end

  # TS-070-S01: MealEntry-Einträge werden beim Rollover NICHT kopiert
  test "TS-070 Speiseplan-Einträge werden beim Jahresübergang nicht übernommen" do
    KindergartenYearRollover.new(@year_2627).execute([ @child.id ])

    assert_equal 0, MealEntry.where(kindergarten_year: @year_2627).count,
      "Im neuen Jahr dürfen keine Speiseplan-Einträge vorhanden sein"
    assert_equal 1, MealEntry.where(kindergarten_year: @year_2526).count,
      "Speiseplan-Eintrag im alten Jahr muss erhalten bleiben"
  end
end
