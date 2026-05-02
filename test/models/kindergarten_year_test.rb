require "test_helper"

class KindergartenYearTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     false
    }.merge(overrides)
  end

  test "has UUID as primary key" do
    year = KindergartenYear.create!(valid_attributes)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, year.id)
  end

  test "has created_at and updated_at timestamps" do
    year = KindergartenYear.create!(valid_attributes)
    assert_not_nil year.created_at
    assert_not_nil year.updated_at
  end

  test "has freely configurable start and end dates" do
    year = KindergartenYear.create!(valid_attributes(start_date: Date.new(2024, 8, 15), end_date: Date.new(2025, 6, 30)))
    assert_equal Date.new(2024, 8, 15), year.start_date
    assert_equal Date.new(2025, 6, 30), year.end_date
  end

  test "activating second year deactivates first" do
    year1 = KindergartenYear.create!(valid_attributes(label: "KGJ 2024/25", active: true))
    assert year1.active?

    year2 = KindergartenYear.create!(valid_attributes(label: "KGJ 2025/26", active: true))
    assert year2.active?

    year1.reload
    assert_not year1.active?, "First year must be deactivated when second becomes active"
  end

  test "exactly one active kindergarten year at a time" do
    KindergartenYear.create!(valid_attributes(label: "KGJ A", active: true))
    KindergartenYear.create!(valid_attributes(label: "KGJ B", active: true))
    KindergartenYear.create!(valid_attributes(label: "KGJ C", active: true))

    assert_equal 1, KindergartenYear.where(active: true).count
  end

  test "label is required" do
    year = KindergartenYear.new(valid_attributes.except(:label))
    assert_not year.valid?
    assert_includes year.errors[:label], "muss ausgefüllt werden"
  end

  test "start_date is required" do
    year = KindergartenYear.new(valid_attributes.except(:start_date))
    assert_not year.valid?
  end

  test "end_date is required" do
    year = KindergartenYear.new(valid_attributes.except(:end_date))
    assert_not year.valid?
  end
end
