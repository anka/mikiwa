require "test_helper"

class SignupListTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Signup-Gruppe")
    @caretaker = User.create!(email: "signup_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "signup_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child = Child.create!(
      first_name: "Signup-Kind", last_name: "A",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = AttendanceList.create!(
      title: "Test-Anmeldeliste",
      mode: "general",
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker,
      deadline: 2.hours.from_now
    )
  end

  teardown do
    @list.attendance_entries.destroy_all
    @list.destroy!
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-040-S01: Elternteil trägt sich ein und nimmt Eintrag zurück
  test "TS-040 Elternteil trägt sich ein und nimmt Eintrag zurück" do
    sign_in_as(@parent)

    post attendance_list_attendance_entries_path(@list), params: {
      attendance_entry: { child_id: @child.id }
    }
    assert_response :redirect

    entry = @list.attendance_entries.find_by(user: @parent)
    assert entry.present?

    delete attendance_list_attendance_entry_path(@list, entry)
    assert_response :redirect

    assert_not AttendanceEntry.exists?(entry.id)
  end

  # TS-040-S02: Nach Anmeldeschluss kein Eintrag möglich
  test "TS-040 Anmeldeschluss verhindert weiteren Eintrag" do
    @list.update!(deadline: 1.hour.ago)

    sign_in_as(@parent)
    post attendance_list_attendance_entries_path(@list), params: {
      attendance_entry: { child_id: @child.id }
    }

    assert_response :unprocessable_entity
  end
end
