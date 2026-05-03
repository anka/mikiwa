# test/models/kindergarten_year_active_scope_test.rb
require "test_helper"

class KindergartenYearActiveScopeTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     false
    }.merge(overrides)
  end

  # --- Happy path ---

  test "KindergartenYear.active returns the active year" do
    inactive = KindergartenYear.create!(valid_attributes(label: "KGJ Inaktiv", active: false))
    active   = KindergartenYear.create!(valid_attributes(label: "KGJ Aktiv", active: true))

    result = KindergartenYear.active

    assert_equal active.id, result.id
    assert_not_equal inactive.id, result.id
  end

  test "KindergartenYear.active returns nil when no active year exists" do
    KindergartenYear.create!(valid_attributes(active: false))

    assert_nil KindergartenYear.active
  end

  # --- Edge cases ---

  test "KindergartenYear.active returns the only active year when multiple inactive years exist" do
    KindergartenYear.create!(valid_attributes(label: "KGJ A", active: false))
    KindergartenYear.create!(valid_attributes(label: "KGJ B", active: false))
    active = KindergartenYear.create!(valid_attributes(label: "KGJ C", active: true))

    assert_equal active.id, KindergartenYear.active.id
  end

  test "KindergartenYear.active reflects the latest activation after switching" do
    first  = KindergartenYear.create!(valid_attributes(label: "KGJ 2024/25", active: true))
    second = KindergartenYear.create!(valid_attributes(label: "KGJ 2025/26", active: true))

    first.reload
    assert_not first.active?, "First year must be inactive after second becomes active"
    assert_equal second.id, KindergartenYear.active.id
  end
end
