require "test_helper"

class PhotoConsentRolloverTest < ActiveSupport::TestCase
  setup do
    @year_2526 = KindergartenYear.create!(
      label: "2025/26-PCRO", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @year_2627 = KindergartenYear.create!(
      label: "2026/27-PCRO", start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 7, 31), active: false
    )
    @group = Group.create!(name: "PC-RO-Gruppe")

    @child_with_consent = Child.create!(
      first_name: "ConsentTrue", last_name: "Rollover",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year_2526, photo_consent: true
    )
    @child_without_consent = Child.create!(
      first_name: "ConsentFalse", last_name: "Rollover",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year_2526, photo_consent: false
    )
  end

  teardown do
    Child.where(last_name: "Rollover").each do |c|
      c.emergency_contacts.destroy_all
      c.parent_children.destroy_all
      c.destroy!
    end
    @group.destroy!
    @year_2627.destroy!
    @year_2526.destroy!
  end

  # TS-072-S01: photo_consent: true wird beim Rollover übernommen
  test "TS-072 Foto-Einwilligung true wird beim Jahresübergang kopiert" do
    KindergartenYearRollover.new(@year_2627).execute([ @child_with_consent.id ])

    new_child = Child.find_by!(
      first_name: "ConsentTrue", last_name: "Rollover", kindergarten_year: @year_2627
    )
    assert new_child.photo_consent, "Foto-Einwilligung true muss im neuen Jahr vorhanden sein"
  end

  # photo_consent: false wird ebenfalls korrekt übertragen
  test "TS-072 Foto-Einwilligung false wird beim Jahresübergang kopiert" do
    KindergartenYearRollover.new(@year_2627).execute([ @child_without_consent.id ])

    new_child = Child.find_by!(
      first_name: "ConsentFalse", last_name: "Rollover", kindergarten_year: @year_2627
    )
    assert_equal false, new_child.photo_consent,
      "Foto-Einwilligung false muss im neuen Jahr vorhanden sein"
  end
end
