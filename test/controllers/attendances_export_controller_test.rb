require "test_helper"

class AttendancesExportControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "F65-Gruppe")
    @year  = KindergartenYear.create!(
      label: "F65-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f65_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "f65_parent@mikiwa.at", password: SecureRandom.hex(20),
                              role: "parent", first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @child1 = Child.create!(first_name: "Anna", last_name: "F65A", date_of_birth: Date.new(2021, 1, 1),
                            group: @group, kindergarten_year: @year, photo_consent: true)
    @child2 = Child.create!(first_name: "Bert", last_name: "F65B", date_of_birth: Date.new(2021, 1, 1),
                            group: @group, kindergarten_year: @year, photo_consent: true)
    Attendance.create!(child: @child1, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 4), present: true, recorded_by: @caretaker)
    Attendance.create!(child: @child2, group: @group, kindergarten_year: @year,
                       date: Date.new(2026, 5, 4), present: false, absence_reason: "sick", recorded_by: @caretaker)
  end

  test "F65 unauthenticated redirects to login" do
    get export_attendances_path
    assert_redirected_to new_session_path
  end

  test "F65 Parent bekommt 403 auf Export-Form" do
    sign_in_as(@parent)
    get export_attendances_path
    assert_response :forbidden
  end

  test "F65 Staff sieht Export-Form" do
    sign_in_as(@caretaker)
    get export_attendances_path
    assert_response :success
    assert_match "Anwesenheit exportieren", response.body
    assert_select "input[name='start_date']"
    assert_select "input[name='end_date']"
    assert_select "select[name='group_id']"
  end

  test "F65 xlsx ohne Params zeigt Validierungsfehler" do
    sign_in_as(@caretaker)
    get export_attendances_path(format: :xlsx)
    assert_response :unprocessable_entity
    assert_match(/Startdatum fehlt|Enddatum fehlt|Gruppe/, response.body)
  end

  test "F65 xlsx mit Span > 92 zeigt Fehler" do
    sign_in_as(@caretaker)
    get export_attendances_path(format: :xlsx,
                                 start_date: "2026-01-01", end_date: "2026-05-01",
                                 group_id: @group.id)
    assert_response :unprocessable_entity
    assert_match(/92 Tage/, response.body)
  end

  test "F65 xlsx mit end < start zeigt Fehler" do
    sign_in_as(@caretaker)
    get export_attendances_path(format: :xlsx,
                                 start_date: "2026-05-10", end_date: "2026-05-01",
                                 group_id: @group.id)
    assert_response :unprocessable_entity
    assert_match(/Ende muss nach Start/, response.body)
  end

  test "F65 xlsx Happy Path liefert Excel-Datei mit korrekten Headern" do
    sign_in_as(@caretaker)
    get export_attendances_path(format: :xlsx,
                                 start_date: "2026-05-04", end_date: "2026-05-08",
                                 group_id: @group.id)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                 response.media_type
    assert_match(/attachment.*mikiwa_anwesenheit/, response.headers["Content-Disposition"])
    assert_match(/2026-05-04.*2026-05-08/, response.headers["Content-Disposition"])
    assert_operator response.body.bytesize, :>, 100
  end

  test "F65 xlsx-Inhalt enthält Kinder und Statuszeichen" do
    require "zip"
    sign_in_as(@caretaker)
    get export_attendances_path(format: :xlsx,
                                 start_date: "2026-05-04", end_date: "2026-05-04",
                                 group_id: @group.id)
    assert_response :success

    tmpfile = Tempfile.new([ "att", ".xlsx" ], binmode: true)
    tmpfile.write(response.body)
    tmpfile.close

    texts = []
    Zip::File.open(tmpfile.path) do |zip|
      [ "xl/sharedStrings.xml", "xl/worksheets/sheet1.xml" ].each do |name|
        entry = zip.find_entry(name)
        next unless entry
        body = +entry.get_input_stream.read
        texts << body.force_encoding("UTF-8")
      end
    end
    blob = texts.join("\n")

    assert_match "Anna F65A", blob
    assert_match "Bert F65B", blob
    # Statuszeichen
    assert_match(/>A<|>X·k</, blob)
  ensure
    tmpfile&.close!
  end

  test "F65 Action-Link 'Exportieren' im /attendances-Header für Staff" do
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    assert_select "a[href='#{export_attendances_path}']"
    assert_match(/Exportieren/, response.body)
  end
end
