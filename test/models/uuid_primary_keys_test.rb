require "test_helper"

class UuidPrimaryKeysTest < ActiveSupport::TestCase
  UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  # TS-020-S01: Gruppe hat UUID
  test "TS-020 Group hat UUID-Primärschlüssel" do
    group = Group.create!(name: "UUID-Test-Gruppe")
    assert_match UUID_PATTERN, group.id
  ensure
    group&.destroy!
  end

  # TS-020-S02: KindergartenYear hat UUID
  test "TS-020 KindergartenYear hat UUID-Primärschlüssel" do
    year = KindergartenYear.create!(
      label: "UUID-Test 2099", start_date: Date.new(2099, 9, 1), end_date: Date.new(2100, 7, 31)
    )
    assert_match UUID_PATTERN, year.id
  ensure
    year&.destroy!
  end

  test "TS-020 Child hat UUID-Primärschlüssel" do
    year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    group = Group.create!(name: "UUID-Test-Child-Gruppe")
    child = Child.create!(
      first_name: "UUID", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: group, kindergarten_year: year, photo_consent: true
    )
    assert_match UUID_PATTERN, child.id
  ensure
    child&.destroy!
    group&.destroy!
  end

  test "TS-020 User hat UUID-Primärschlüssel" do
    user = User.create!(email: "uuid_pk_test@test.de", password: "sicherespasswort1234")
    assert_match UUID_PATTERN, user.id
  ensure
    user&.destroy!
  end
end
