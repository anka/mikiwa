require "test_helper"

class ChildrenAttendanceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "F64-Gruppe")
    @year  = KindergartenYear.create!(
      label: "F64-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f64_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent_linked = User.create!(email: "f64_parent_linked@mikiwa.at", password: SecureRandom.hex(20),
                                  role: "parent", first_name: "Mama", last_name: "Linked", phone: "0664 000 000")
    @parent_other  = User.create!(email: "f64_parent_other@mikiwa.at", password: SecureRandom.hex(20),
                                  role: "parent", first_name: "Mama", last_name: "Other", phone: "0664 000 001")
    @child = Child.create!(
      first_name: "Mila", last_name: "F64",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent_linked, child: @child)
  end

  test "F64 unauthenticated wird auf Login geleitet" do
    get attendance_child_path(@child)
    assert_redirected_to new_session_path
  end

  test "F64 Staff sieht Kalender mit Status-Mix" do
    sign_in_as(@caretaker)
    Attendance.create!(child: @child, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 4), present: true, recorded_by: @caretaker)
    Attendance.create!(child: @child, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 5), present: false, absence_reason: "sick", recorded_by: @caretaker)

    get attendance_child_path(@child, month: "2026-05")
    assert_response :success
    assert_select ".mw-attendance-day--present", minimum: 1
    assert_select ".mw-attendance-day--absent", minimum: 1
    # Grund als Tooltip
    assert_match(/Krank/i, response.body)
  end

  test "F64 verlinkter Elternteil sieht Kalender" do
    sign_in_as(@parent_linked)
    get attendance_child_path(@child, month: "2026-05")
    assert_response :success
    assert_match "Anwesenheit", response.body
  end

  test "F64 fremder Elternteil bekommt 403" do
    sign_in_as(@parent_other)
    get attendance_child_path(@child, month: "2026-05")
    assert_response :forbidden
  end

  test "F64 default-Monat ist aktueller Monat" do
    sign_in_as(@caretaker)
    get attendance_child_path(@child)
    assert_response :success
    assert_match(/#{I18n.l(Date.current, format: "%B %Y")}/, response.body)
  end

  test "F64 Monatsnavigation ‹ › liefert prev/next-Links" do
    sign_in_as(@caretaker)
    get attendance_child_path(@child, month: "2026-05")
    assert_response :success
    assert_select "a[href*='month=2026-04']", minimum: 1
    assert_select "a[href*='month=2026-06']", minimum: 1
  end

  test "F64 Action-Button 'Anwesenheit' erscheint in Child-Show für Staff" do
    sign_in_as(@caretaker)
    get child_path(@child)
    assert_response :success
    assert_select "a[href='#{attendance_child_path(@child)}']"
    assert_match(/Anwesenheit/, response.body)
  end

  test "F64 Action-Button 'Anwesenheit' erscheint in Child-Show für verlinkten Elternteil" do
    sign_in_as(@parent_linked)
    get child_path(@child)
    assert_response :success
    assert_select "a[href='#{attendance_child_path(@child)}']"
  end

  test "F64 Tage außerhalb des Monats sind als empty markiert" do
    sign_in_as(@caretaker)
    # Mai 2026 beginnt an einem Freitag → Mo–Do davor sind außerhalb des Monats
    get attendance_child_path(@child, month: "2026-05")
    assert_response :success
    assert_select ".mw-attendance-day--outside", minimum: 1
  end
end
