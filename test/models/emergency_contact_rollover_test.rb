require "test_helper"

class EmergencyContactRolloverTest < ActiveSupport::TestCase
  setup do
    @year_2526 = KindergartenYear.create!(
      label: "2025/26-ECRO", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @year_2627 = KindergartenYear.create!(
      label: "2026/27-ECRO", start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 7, 31), active: false
    )
    @group = Group.create!(name: "EC-RO-Gruppe")

    @child = Child.create!(
      first_name: "ECRollover", last_name: "Kind",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year_2526, photo_consent: true
    )
    EmergencyContact.create!(
      child: @child, name: "Oma Anna", phone: "+43 664 111 222", relationship: "Großmutter", position: 1
    )
    EmergencyContact.create!(
      child: @child, name: "Opa Fritz", phone: "+43 664 333 444", relationship: "Großvater", position: 2
    )
  end

  teardown do
    Child.where(last_name: "Kind", first_name: "ECRollover").each do |c|
      c.emergency_contacts.destroy_all
      c.parent_children.destroy_all
      c.destroy!
    end
    @group.destroy!
    @year_2627.destroy!
    @year_2526.destroy!
  end

  # TS-071-S01: Notfallkontakte werden beim Rollover kopiert
  test "TS-071 Notfallkontakte werden beim Jahresübergang kopiert" do
    KindergartenYearRollover.new(@year_2627).execute([ @child.id ])

    new_child = Child.find_by!(
      first_name: "ECRollover", last_name: "Kind", kindergarten_year: @year_2627
    )
    assert_equal 2, new_child.emergency_contacts.count,
      "Neues Kind muss 2 Notfallkontakte haben"
  end

  # Kopie ist unabhängig – Änderung im neuen Jahr ändert nicht altes Jahr
  test "TS-071 Notfallkontakte im neuen Jahr sind unabhängig vom alten Jahr" do
    KindergartenYearRollover.new(@year_2627).execute([ @child.id ])

    new_child = Child.find_by!(
      first_name: "ECRollover", last_name: "Kind", kindergarten_year: @year_2627
    )
    new_child.emergency_contacts.first.update!(name: "Geändert")

    assert_equal "Oma Anna", @child.emergency_contacts.first.name,
      "Änderung im neuen Jahr darf alten Kontakt nicht ändern"
  end
end
