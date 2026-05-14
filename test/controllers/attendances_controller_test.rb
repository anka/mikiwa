require "test_helper"

class AttendancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "F63-Test-Bären")
    @year  = KindergartenYear.create!(
      label: "F63-KGJ-Ctrl", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f63_ctrl_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "f63_ctrl_parent@mikiwa.at",    password: SecureRandom.hex(20), role: "parent",
                               first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @child1 = Child.create!(
      first_name: "Anna", last_name: "F63A", date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    @child2 = Child.create!(
      first_name: "Bert", last_name: "F63B", date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
  end

  test "F63 unauthenticated user wird auf Login geleitet" do
    get attendances_path
    assert_redirected_to new_session_path
  end

  test "F63 Parent bekommt 403 auf /attendances" do
    sign_in_as(@parent)
    get attendances_path
    assert_response :forbidden
  end

  test "F63 Staff sieht Filter ohne Gruppe → Hinweistext" do
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    assert_match(/Bitte Gruppe wählen/i, response.body)
  end

  test "F63 Staff sieht Kindertabelle mit Gruppen-Filter" do
    sign_in_as(@caretaker)
    get attendances_path(date: "2026-05-14", group_id: @group.id)
    assert_response :success
    assert_match "Anna F63A", response.body
    assert_match "Bert F63B", response.body
    assert_select 'input[type="checkbox"][name*="present"]'
    assert_select 'select[name*="absence_reason"]'
  end

  test "F63 Bulk-Create speichert alle Attendance-Datensätze" do
    sign_in_as(@caretaker)
    assert_difference "Attendance.count", 2 do
      post attendances_path, params: {
        date: "2026-05-14",
        group_id: @group.id,
        attendances: {
          @child1.id => { present: "1", absence_reason: "", note: "" },
          @child2.id => { present: "0", absence_reason: "sick", note: "Fieber" }
        }
      }
    end
    assert_redirected_to attendances_path(date: "2026-05-14", group_id: @group.id)
    a1 = Attendance.find_by!(child: @child1, date: "2026-05-14")
    a2 = Attendance.find_by!(child: @child2, date: "2026-05-14")
    assert a1.present
    assert_not a2.present
    assert_equal "sick", a2.absence_reason
    assert_equal "Fieber", a2.note
    assert_equal @caretaker.id, a1.recorded_by_id
  end

  test "F63 Upsert: zweites Submit aktualisiert statt neu anzulegen" do
    sign_in_as(@caretaker)
    post attendances_path, params: {
      date: "2026-05-14", group_id: @group.id,
      attendances: { @child1.id => { present: "1", absence_reason: "", note: "" } }
    }
    assert_no_difference "Attendance.count" do
      post attendances_path, params: {
        date: "2026-05-14", group_id: @group.id,
        attendances: { @child1.id => { present: "0", absence_reason: "vacation", note: "" } }
      }
    end
    a = Attendance.find_by!(child: @child1, date: "2026-05-14")
    assert_not a.present
    assert_equal "vacation", a.absence_reason
  end

  test "F63 unchecked Checkbox → present=false (kein NOT-NULL-Crash)" do
    # check_box_tag sendet bei unchecked keinen Key. View ergänzt
    # einen hidden_field 'present=0' davor; Controller casted defensiv
    # auf false. Test simuliert beides indirekt.
    sign_in_as(@caretaker)
    post attendances_path, params: {
      date: "2026-05-14", group_id: @group.id,
      attendances: {
        @child1.id => { present: "0", absence_reason: "sick", note: "" }
      }
    }
    assert_redirected_to attendances_path(date: "2026-05-14", group_id: @group.id)
    a = Attendance.find_by!(child: @child1, date: "2026-05-14")
    assert_equal false, a.present
    assert_equal "sick", a.absence_reason
  end

  test "F63 View rendert hidden_field present=0 vor jeder Checkbox" do
    sign_in_as(@caretaker)
    get attendances_path(date: "2026-05-14", group_id: @group.id)
    assert_response :success
    # Jede Zeile braucht einen hidden_field present=0 vor der Checkbox
    # (sonst sendet HTML bei unchecked nichts → NOT-NULL-Violation).
    assert_select 'input[type="hidden"][name*="present"][value="0"]', minimum: 2
  end

  test "F63 Parent bekommt 403 beim Bulk-Submit" do
    sign_in_as(@parent)
    post attendances_path, params: {
      date: "2026-05-14", group_id: @group.id,
      attendances: { @child1.id => { present: "1" } }
    }
    assert_response :forbidden
  end

  test "F63 Sidebar zeigt Anwesenheit-Eintrag für Staff" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
    assert_match(/Anwesenheit/, response.body)
    assert_select 'a[href="/attendances"]'
  end

  test "F63 Sidebar zeigt KEINEN Anwesenheit-Eintrag für Parent" do
    sign_in_as(@parent)
    get children_path
    assert_response :success
    assert_select 'a[href="/attendances"]', count: 0
  end
end
