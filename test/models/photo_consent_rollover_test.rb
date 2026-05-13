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

  # BF-007: Beim Rollover behält das (selbe) Kind seine Foto-Einwilligung.
  test "BF-007 Foto-Einwilligung true bleibt nach Jahresübergang am bestehenden Kind" do
    KindergartenYearRollover.new(@year_2627).execute([ @child_with_consent.id ])
    @child_with_consent.reload
    assert_equal @year_2627.id, @child_with_consent.kindergarten_year_id
    assert @child_with_consent.photo_consent
  end

  test "BF-007 Foto-Einwilligung false bleibt nach Jahresübergang am bestehenden Kind" do
    KindergartenYearRollover.new(@year_2627).execute([ @child_without_consent.id ])
    @child_without_consent.reload
    assert_equal @year_2627.id, @child_without_consent.kindergarten_year_id
    assert_equal false, @child_without_consent.photo_consent
  end
end
