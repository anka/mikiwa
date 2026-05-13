require "test_helper"

class AttendanceListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_alc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_alc@mikiwa.at",   password: SecureRandom.hex(20),   role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Listen-Bären2")
    @group_loewen = Group.create!(name: "Listen-Löwen2")

    @child = Child.create!(
      first_name: "Paul", last_name: "Renn",
      date_of_birth: Date.new(2021, 1, 5),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = AttendanceList.create!(
      title: "Waldtag", mode: "general",
      kindergarten_year: @year, group: @group_baeren,
      created_by: @caretaker
    )
    @other_list = AttendanceList.create!(
      title: "Löwen-Ausflug", mode: "general",
      kindergarten_year: @year, group: @group_loewen,
      created_by: @caretaker
    )
  end

  # --- Index ---
  test "unauthenticated user is redirected" do
    get attendance_lists_path
    assert_redirected_to new_session_path
  end

  test "caretaker sees all lists" do
    sign_in_as(@caretaker)
    get attendance_lists_path
    assert_response :success
    assert_match "Waldtag", response.body
    assert_match "Löwen-Ausflug", response.body
  end

  test "parent sees only lists for own group" do
    sign_in_as(@parent)
    get attendance_lists_path
    assert_response :success
    assert_match "Waldtag", response.body
    assert_no_match "Löwen-Ausflug", response.body
  end

  # --- Create ---
  test "caretaker can create list" do
    sign_in_as(@caretaker)
    assert_difference "AttendanceList.count", 1 do
      post attendance_lists_path, params: {
        attendance_list: {
          title: "Neuer Ausflug", mode: "general",
          kindergarten_year_id: @year.id, group_id: @group_baeren.id
        }
      }
    end
    assert_redirected_to attendance_list_path(AttendanceList.order(:created_at).last)
  end

  test "parent cannot create list (403)" do
    sign_in_as(@parent)
    post attendance_lists_path, params: {
      attendance_list: { title: "X", mode: "general", kindergarten_year_id: @year.id, group_id: @group_baeren.id }
    }
    assert_response :forbidden
  end

  # --- Entries ---
  test "parent can add entry for own child (Eintragen)" do
    sign_in_as(@parent)
    assert_difference "AttendanceEntry.count", 1 do
      post attendance_list_attendance_entries_path(@list), params: {
        attendance_entry: { child_id: @child.id }
      }
    end
    assert_redirected_to attendance_list_path(@list)
  end

  test "parent cannot enter after deadline (Anmeldeschluss)" do
    @list.update!(deadline: 2.days.ago)
    sign_in_as(@parent)
    assert_no_difference "AttendanceEntry.count" do
      post attendance_list_attendance_entries_path(@list), params: {
        attendance_entry: { child_id: @child.id }
      }
    end
    assert_response :unprocessable_entity
  end

  test "parent can remove own entry while deadline not passed (Rücknahme)" do
    sign_in_as(@parent)
    entry = AttendanceEntry.create!(list: @list, child: @child, user: @parent)
    assert_difference "AttendanceEntry.count", -1 do
      delete attendance_list_attendance_entry_path(@list, entry)
    end
    assert_redirected_to attendance_list_path(@list)
  end

  test "parent cannot remove entry after deadline" do
    @list.update!(deadline: 2.days.ago)
    sign_in_as(@parent)
    entry = AttendanceEntry.create!(list: @list, child: @child, user: @parent)
    assert_no_difference "AttendanceEntry.count" do
      delete attendance_list_attendance_entry_path(@list, entry)
    end
    assert_response :unprocessable_entity
  end

  # TS-041-S01: Betreuer exportiert Liste als CSV mit allen Einträgen
  test "TS-041 CSV-Export enthält alle eingetragenen Kinder" do
    child2 = Child.create!(
      first_name: "Mia", last_name: "Kraft",
      date_of_birth: Date.new(2021, 3, 10),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    child3 = Child.create!(
      first_name: "Leo", last_name: "Steyr",
      date_of_birth: Date.new(2020, 7, 22),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    parent2 = User.create!(email: "csv_p2@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "CSV", last_name: "Parent2", phone: "0664 000 002")
    parent3 = User.create!(email: "csv_p3@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "CSV", last_name: "Parent3", phone: "0664 000 003")
    ParentChild.create!(user: parent2, child: child2)
    ParentChild.create!(user: parent3, child: child3)

    AttendanceEntry.create!(list: @list, child: @child,  user: @parent)
    AttendanceEntry.create!(list: @list, child: child2, user: parent2)
    AttendanceEntry.create!(list: @list, child: child3, user: parent3)

    sign_in_as(@caretaker)
    get export_attendance_list_path(@list, format: :csv)

    assert_response :success
    assert_match "text/csv", response.content_type
    assert_match @child.full_name,  response.body
    assert_match child2.full_name,  response.body
    assert_match child3.full_name,  response.body

    data_lines = response.body.lines.reject { |l| l.strip.empty? }
    assert data_lines.size >= 4, "Header + 3 Datenzeilen erwartet, war #{data_lines.size}"
  ensure
    AttendanceEntry.where(list: @list).destroy_all
    ParentChild.where(user: [ parent2, parent3 ]).destroy_all
    [ child2, child3, parent2, parent3 ].each(&:destroy!)
  end

  # --- CSV export ---
  test "caretaker can download CSV export" do
    AttendanceEntry.create!(list: @list, child: @child, user: @parent)
    sign_in_as(@caretaker)
    get export_attendance_list_path(@list, format: :csv)
    assert_response :success
    assert_match "text/csv", response.content_type
    assert_match @child.full_name, response.body
  end

  test "parent cannot download CSV export (403)" do
    sign_in_as(@parent)
    get export_attendance_list_path(@list, format: :csv)
    assert_response :forbidden
  end
end
