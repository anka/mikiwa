require "test_helper"

class AttendancesNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @baeren = Group.create!(name: "F71-Bären")
    @loewen = Group.create!(name: "F71-Löwen")
    @year   = KindergartenYear.create!(
      label: "F71-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(
      email: "f71_caretaker@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
    @child_a = Child.create!(
      first_name: "Anna", last_name: "F71A", date_of_birth: Date.new(2021, 1, 1),
      group: @baeren, kindergarten_year: @year, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "Bert", last_name: "F71B", date_of_birth: Date.new(2021, 1, 1),
      group: @baeren, kindergarten_year: @year, photo_consent: true
    )
    @child_l = Child.create!(
      first_name: "Lara", last_name: "F71L", date_of_birth: Date.new(2021, 1, 1),
      group: @loewen, kindergarten_year: @year, photo_consent: true
    )
  end

  test "F71 /attendances zeigt direkt heutige Liste der ersten Gruppe" do
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    # Erste Gruppe alphabetisch ist F71-Bären
    assert_match "Anna F71A", response.body
    assert_match "Bert F71B", response.body
    # Lara aus Löwen darf NICHT sichtbar sein
    assert_no_match "Lara F71L", response.body
    # Kein „Bitte Gruppe wählen“-Hinweis mehr
    assert_no_match(/Bitte Gruppe wählen/i, response.body)
  end

  test "F71 Tab-Leiste bei >1 Gruppe sichtbar mit aktivem Tab" do
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    assert_select ".mw-tabs"
    assert_select ".mw-tab", minimum: 2
    # Aktive Tab markiert
    assert_select ".mw-tab.mw-tab--active", text: /F71-Bären/
  end

  test "F71 Tab-Link enthält aktuelles Datum als Query-Param" do
    sign_in_as(@caretaker)
    get attendances_path(date: "2026-04-10")
    assert_response :success
    expected_href = attendances_path(group_id: @loewen.id, date: "2026-04-10")
    assert_select "a.mw-tab[href=?]", expected_href
  end

  test "F71 Bei nur 1 Gruppe wird KEINE Tab-Leiste gerendert" do
    @child_l.destroy
    Group.where.not(id: @baeren.id).destroy_all
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    assert_select ".mw-tabs", count: 0
  end

  test "F71 mw-filters Markup ist nicht mehr im DOM" do
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    assert_select "form.mw-filters", count: 0
    assert_select ".mw-filters__row", count: 0
    assert_select "input[name='q']", count: 0
  end

  test "F71 Date-Navigation: ‹ › Pfeile + Date-Picker" do
    sign_in_as(@caretaker)
    get attendances_path(date: "2026-05-15", group_id: @baeren.id)
    assert_response :success
    assert_select ".mw-attendance-date-nav"
    # Vorheriger Tag = 2026-05-14, nächster Tag = 2026-05-16
    assert_select ".mw-attendance-date-nav a[href=?]",
                  attendances_path(group_id: @baeren.id, date: "2026-05-14")
    assert_select ".mw-attendance-date-nav a[href=?]",
                  attendances_path(group_id: @baeren.id, date: "2026-05-16")
    # Date-Picker mit Stimulus-Controller
    assert_select ".mw-attendance-date-nav input[type='date'][value=?]", "2026-05-15"
    assert_select ".mw-attendance-date-nav input[type='date'][data-controller~='date-jump']"
  end

  test "F71 Heute-Button nur sichtbar wenn Datum nicht heute ist" do
    sign_in_as(@caretaker)
    # Datum = heute → kein Heute-Button
    get attendances_path
    assert_response :success
    assert_select ".mw-attendance-date-nav__today", count: 0

    # Datum != heute → Heute-Button sichtbar
    get attendances_path(date: "2026-04-15", group_id: @baeren.id)
    assert_response :success
    assert_select ".mw-attendance-date-nav__today[href=?]",
                  attendances_path(group_id: @baeren.id, date: Date.current.to_fs(:iso8601))
  end

  test "F71 Per-Row Form statt einem großen Form" do
    sign_in_as(@caretaker)
    get attendances_path
    assert_response :success
    # 2 aktive Bären-Kinder = 2 Per-Row-Formen
    assert_select "form[data-controller~='auto-submit']", count: 2
    # Kein zentraler Speichern-Button mehr
    assert_select "input[type='submit'][value='Speichern']", count: 0
  end

  test "F71 Auto-Save via Turbo-Stream gibt 200 statt Redirect zurück" do
    sign_in_as(@caretaker)
    post attendances_path,
         params: {
           date: "2026-05-14",
           group_id: @baeren.id,
           attendances: { @child_a.id => { present: "1", absence_reason: "", note: "" } }
         },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.media_type + "; charset=utf-8"
    a = Attendance.find_by!(child: @child_a, date: "2026-05-14")
    assert a.present
  end

  test "F71 Stimulus date-jump Controller existiert" do
    path = Rails.root.join("app/javascript/controllers/date_jump_controller.js")
    assert File.exist?(path), "date-jump Stimulus-Controller fehlt"
  end

  test "F71 _filters.html.haml wurde entfernt" do
    path = Rails.root.join("app/views/attendances/_filters.html.haml")
    assert_not File.exist?(path), "_filters.html.haml soll gelöscht sein"
  end
end
