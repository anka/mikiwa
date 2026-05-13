require "test_helper"

class SignupListDateModeTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Datum-Gruppe")
    @caretaker = User.create!(
      email: "datumlist_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @parent = User.create!(
      email: "datumlist_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000"
    )
    @child = Child.create!(
      first_name: "DatumKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = AttendanceList.create!(
      title: "Ausflug-Pro-Datum",
      mode: "per_date",
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @opt1 = AttendanceDateOption.create!(attendance_list: @list, date: Date.new(2026, 6, 1))
    @opt2 = AttendanceDateOption.create!(attendance_list: @list, date: Date.new(2026, 6, 8))
    @opt3 = AttendanceDateOption.create!(attendance_list: @list, date: Date.new(2026, 6, 15))

    @entry = AttendanceEntry.create!(list: @list, child: @child, user: @parent)
    AttendanceDateSelection.create!(attendance_entry: @entry, attendance_date_option: @opt1)
    AttendanceDateSelection.create!(attendance_entry: @entry, attendance_date_option: @opt3)
  end

  teardown do
    @entry.attendance_date_selections.destroy_all
    @entry.destroy!
    @list.attendance_date_options.destroy_all
    @list.destroy!
    ParentChild.where(user: @parent, child: @child).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-065-S01: Eintrag zeigt 2 ausgewählte Termine; Option 2 nicht gewählt
  test "TS-065 Pro-Datum-Liste zeigt gewählte und nicht gewählte Optionen korrekt" do
    sign_in_as(@caretaker)
    get attendance_list_path(@list)

    assert_response :success

    body = response.body
    date1_label = I18n.l(@opt1.date, format: :short)
    date2_label = I18n.l(@opt2.date, format: :short)
    date3_label = I18n.l(@opt3.date, format: :short)

    assert_match date1_label, body, "Option 1 sollte in der Tabelle erscheinen"
    assert_match date2_label, body, "Option 2 sollte in der Tabelle erscheinen"
    assert_match date3_label, body, "Option 3 sollte in der Tabelle erscheinen"

    selections = @entry.attendance_date_selections.map(&:attendance_date_option_id).to_set
    assert selections.include?(@opt1.id), "Option 1 muss als gewählt gespeichert sein"
    assert_not selections.include?(@opt2.id), "Option 2 darf nicht gewählt sein"
    assert selections.include?(@opt3.id), "Option 3 muss als gewählt gespeichert sein"
    assert_equal 2, selections.size, "Genau 2 Optionen müssen ausgewählt sein"
  end

  test "TS-065 CSV-Export enthält Ja/Nein pro Datum" do
    sign_in_as(@caretaker)
    get export_attendance_list_path(@list, format: :csv)

    assert_response :success
    csv_body = response.body.encode("UTF-8", invalid: :replace, undef: :replace)

    lines = csv_body.lines.reject { |l| l.strip.empty? }
    assert lines.size >= 2, "CSV muss Header und mindestens eine Datenzeile enthalten"

    data_line = lines[1]
    assert_match "Ja", data_line, "CSV muss 'Ja' für gewählte Optionen enthalten"
    assert_match "Nein", data_line, "CSV muss 'Nein' für nicht gewählte Optionen enthalten"
  end
end
