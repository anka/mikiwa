require "test_helper"

class ParentDashboardOpenListTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "OL-Dashboard-Gruppe")
    @caretaker = User.create!(
      email: "ol_dash_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @parent = User.create!(
      email: "ol_dash_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent"
    )
    @child = Child.create!(
      first_name: "OLKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = AttendanceList.create!(
      title: "Offene-Anmelde-Liste",
      mode: "general",
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker
    )
  end

  teardown do
    AttendanceEntry.where(list: @list).destroy_all
    @list.destroy!
    ParentChild.where(user: @parent, child: @child).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-075-S01: Offene Liste verschwindet aus Dashboard nach Eintrag
  test "TS-075 Offene Liste verschwindet aus Eltern-Dashboard nach Eintrag" do
    sign_in_as(@parent)

    get parent_dashboard_path
    assert_response :success
    assert_match "Offene-Anmelde-Liste", response.body, "Liste muss vor Eintrag im Dashboard erscheinen"

    post attendance_list_attendance_entries_path(@list), params: {
      attendance_entry: { child_id: @child.id }
    }
    assert_response :redirect

    get parent_dashboard_path
    assert_response :success
    assert_no_match "Offene-Anmelde-Liste", response.body,
      "Liste darf nach Eintrag nicht mehr in offenen Listen erscheinen"
  end
end
