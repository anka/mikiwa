require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "F63-Gruppe")
    @year  = KindergartenYear.create!(
      label: "F63-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f63_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @child = Child.create!(
      first_name: "Test", last_name: "F63",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
  end

  test "F63 valider Anwesend-Eintrag wird gespeichert" do
    a = Attendance.new(child: @child, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 14), present: true, recorded_by: @caretaker)
    assert a.save, a.errors.full_messages.inspect
  end

  test "F63 UUID-Primary-Key" do
    a = Attendance.create!(child: @child, group: @group, kindergarten_year: @year,
                            date: Date.new(2026, 5, 14), present: true, recorded_by: @caretaker)
    assert_match(/\A[0-9a-f-]{36}\z/, a.id)
  end

  test "F63 absence_reason-Enum hat sick/vacation/appointment/other" do
    assert_equal(
      { "sick" => "sick", "vacation" => "vacation", "appointment" => "appointment", "other" => "other" },
      Attendance.absence_reasons
    )
  end

  test "F63 abwesendes Kind mit Grund ist valide" do
    a = Attendance.new(child: @child, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 14), present: false,
                       absence_reason: "sick", recorded_by: @caretaker)
    assert a.valid?, a.errors.full_messages.inspect
  end

  test "F63 abwesendes Kind ohne Grund ist valide (Grund optional)" do
    a = Attendance.new(child: @child, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 14), present: false, recorded_by: @caretaker)
    assert a.valid?
  end

  test "F63 anwesendes Kind mit absence_reason ist ungültig" do
    a = Attendance.new(child: @child, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 14), present: true,
                       absence_reason: "sick", recorded_by: @caretaker)
    assert_not a.valid?
    assert a.errors[:absence_reason].any?
  end

  test "F63 unique (child_id, date) verhindert Duplikat" do
    Attendance.create!(child: @child, group: @group, kindergarten_year: @year,
                        date: Date.new(2026, 5, 14), present: true, recorded_by: @caretaker)
    dup = Attendance.new(child: @child, group: @group, kindergarten_year: @year,
                          date: Date.new(2026, 5, 14), present: false, recorded_by: @caretaker)
    assert_not dup.valid?
    assert dup.errors[:date].any? || dup.errors[:child_id].any?
  end

  test "F63 Pflichtfelder werden validiert" do
    a = Attendance.new
    assert_not a.valid?
    assert a.errors[:child].any?
    assert a.errors[:group].any?
    assert a.errors[:kindergarten_year].any?
    assert a.errors[:date].any?
    assert a.errors[:recorded_by].any?
  end

  test "F63 Scopes for_date/for_group/for_child/in_month" do
    a1 = Attendance.create!(child: @child, group: @group, kindergarten_year: @year,
                             date: Date.new(2026, 5, 14), present: true, recorded_by: @caretaker)
    other_child = Child.create!(
      first_name: "Other", last_name: "F63",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    Attendance.create!(child: other_child, group: @group, kindergarten_year: @year,
                        date: Date.new(2026, 6, 1), present: false, recorded_by: @caretaker)

    assert_includes Attendance.for_date(Date.new(2026, 5, 14)), a1
    assert_includes Attendance.for_group(@group.id), a1
    assert_includes Attendance.for_child(@child.id), a1
    assert_equal 1, Attendance.in_month(Date.new(2026, 5, 14)).count
  end
end
