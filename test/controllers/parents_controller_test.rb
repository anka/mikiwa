require "test_helper"

class ParentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_p@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(
      email: "eltern_p@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Anna",
      last_name: "Huber",
      phone: "0664 123 456"
    )
  end

  test "Betreuer kann Eltern-Liste aufrufen" do
    sign_in_as(@caretaker)
    get parents_path
    assert_response :success
  end

  test "Elternteil kann Eltern-Liste nicht aufrufen (403)" do
    sign_in_as(@parent)
    get parents_path
    assert_response :forbidden
  end

  test "Betreuer kann Eltern-Account anlegen und Einladungs-Mail wird versandt" do
    sign_in_as(@caretaker)
    assert_emails 1 do
      assert_difference "User.count", 1 do
        post parents_path, params: {
          user: {
            email: "neues.elternteil@test.at",
            first_name: "Max",
            last_name: "Muster",
            phone: "0650 999 888"
          }
        }
      end
    end
    new_parent = User.find_by!(email: "neues.elternteil@test.at")
    assert_equal "parent", new_parent.role
    assert_equal "Max", new_parent.first_name
    assert_redirected_to parents_path
  end

  test "Betreuer kann Eltern-Account deaktivieren" do
    sign_in_as(@caretaker)
    patch lock_parent_path(@parent)
    assert @parent.reload.locked?
  end

  test "Betreuer kann Re-Einladung senden" do
    sign_in_as(@caretaker)
    assert_emails 1 do
      post reinvite_parent_path(@parent)
    end
    assert_redirected_to parents_path
  end

  test "Re-Einladung invalidiert vorherigen Token" do
    sign_in_as(@caretaker)
    old_version = @parent.magic_link_token_version
    post reinvite_parent_path(@parent)
    assert_operator @parent.reload.magic_link_token_version, :>, old_version
  end

  # F20: Eltern-Daten von Betreuern bearbeitbar
  test "F20 Betreuer kann Edit-Seite eines Eltern-Users öffnen" do
    sign_in_as(@caretaker)
    get edit_parent_path(@parent)
    assert_response :success
    assert_match @parent.email, response.body
  end

  test "F20 Betreuer kann Eltern-Stammdaten aktualisieren" do
    sign_in_as(@caretaker)
    patch parent_path(@parent), params: {
      user: {
        first_name: "Andrea",
        last_name:  "Müller",
        email:      "andrea.mueller@test.at",
        phone:      "0660 111 222"
      }
    }
    assert_redirected_to parents_path
    @parent.reload
    assert_equal "Andrea", @parent.first_name
    assert_equal "Müller", @parent.last_name
    assert_equal "andrea.mueller@test.at", @parent.email
    assert_equal "0660 111 222", @parent.phone
  end

  test "F20 Betreuer kann Edit-Seite eines Admin/Staff-Users NICHT öffnen (403)" do
    sign_in_as(@caretaker)
    other_caretaker = User.create!(email: "andere_betreuerin@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    get edit_parent_path(other_caretaker)
    assert_response :forbidden
  end

  test "F20 Eltern darf NICHT Edit-Seite eines anderen Eltern-Users aufrufen (403)" do
    sign_in_as(@parent)
    other = User.create!(email: "andere_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    get edit_parent_path(other)
    assert_response :forbidden
  end

  test "F20 Update mit ungültigen Daten zeigt edit erneut" do
    sign_in_as(@caretaker)
    patch parent_path(@parent), params: { user: { email: "" } }
    assert_response :unprocessable_entity
  end

  # F20 R-P0-003: Eltern-Liste mit Suchfunktion
  test "F20 Eltern-Liste filtert nach Suchparameter q (Name)" do
    sign_in_as(@caretaker)
    User.create!(email: "felix@test.at", password: SecureRandom.hex(20),
                 role: "parent", first_name: "Felix", last_name: "Schmidt", phone: "0664 000 010")
    User.create!(email: "gerda@test.at", password: SecureRandom.hex(20),
                 role: "parent", first_name: "Gerda", last_name: "Bauer", phone: "0664 000 011")

    get parents_path, params: { q: "Felix" }
    assert_response :success
    assert_match "Felix", response.body
    assert_no_match "Gerda", response.body
  end

  test "F20 Eltern-Liste filtert nach E-Mail" do
    sign_in_as(@caretaker)
    User.create!(email: "felix@test.at", password: SecureRandom.hex(20),
                 role: "parent", first_name: "Felix", last_name: "Schmidt", phone: "0664 000 010")

    get parents_path, params: { q: "felix@test" }
    assert_response :success
    assert_match "Felix", response.body
  end

  # F21: Eltern-Detailansicht (Show-Seite)
  test "F21 Betreuer kann Eltern-Show-Seite öffnen" do
    sign_in_as(@caretaker)
    get parent_path(@parent)
    assert_response :success
    assert_match @parent.email, response.body
    assert_match "Anna", response.body
    assert_match "Huber", response.body
  end

  test "F21 Show zeigt zugeordnete Kinder mit Foto-Consent-Badge" do
    sign_in_as(@caretaker)
    group = Group.create!(name: "Show-Bären")
    year  = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    child_yes = Child.create!(
      first_name: "Lukas", last_name: "Huber",
      date_of_birth: Date.new(2021, 3, 1),
      group: group, kindergarten_year: year, photo_consent: true
    )
    child_no = Child.create!(
      first_name: "Mia", last_name: "Huber",
      date_of_birth: Date.new(2022, 6, 1),
      group: group, kindergarten_year: year, photo_consent: false
    )
    ParentChild.create!(user: @parent, child: child_yes)
    ParentChild.create!(user: @parent, child: child_no)

    get parent_path(@parent)
    assert_response :success
    assert_match "Lukas", response.body
    assert_match "Mia", response.body
    assert_match "Erteilt", response.body
    assert_match "Nicht erteilt", response.body
  end

  test "F21 Show zeigt Empty-State wenn keine Kinder zugeordnet" do
    sign_in_as(@caretaker)
    get parent_path(@parent)
    assert_response :success
    assert_match(/Keine Kinder zugeordnet/i, response.body)
  end

  test "F21 Eltern darf eigene Show-Seite öffnen" do
    sign_in_as(@parent)
    get parent_path(@parent)
    assert_response :success
  end

  test "F21 Eltern darf Show-Seite eines anderen Eltern NICHT öffnen (403)" do
    sign_in_as(@parent)
    other = User.create!(email: "fremde_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    get parent_path(other)
    assert_response :forbidden
  end

  test "F21 Show enthält Bearbeiten-Aktion für Staff" do
    sign_in_as(@caretaker)
    get parent_path(@parent)
    assert_response :success
    assert_match edit_parent_path(@parent), response.body
  end

  # F43: knowhow & notes
  test "F43 Caretaker kann knowhow und notes setzen" do
    sign_in_as(@caretaker)
    patch parent_path(@parent), params: {
      user: { email: @parent.email, first_name: @parent.first_name, last_name: @parent.last_name,
              phone: @parent.phone, knowhow: "Bauer, Traktor-Fahrten", notes: "Sehr engagiert" }
    }
    assert_redirected_to parents_path
    @parent.reload
    assert_equal "Bauer, Traktor-Fahrten", @parent.knowhow
    assert_equal "Sehr engagiert", @parent.notes
  end

  test "F43 Show zeigt Über-Sektion mit knowhow und notes" do
    sign_in_as(@caretaker)
    @parent.update!(knowhow: "Bäcker", notes: "Hilft sehr gerne")
    get parent_path(@parent)
    assert_response :success
    assert_match(/Über/, response.body)
    assert_match "Bäcker", response.body
    assert_match "Hilft sehr gerne", response.body
  end

  test "F43 Liste zeigt knowhow-Spalte (truncate 60)" do
    sign_in_as(@caretaker)
    long_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor"
    @parent.update!(knowhow: long_text)
    get parents_path
    assert_response :success
    assert_match(/Wissen|Fähigkeiten/i, response.body)
    assert_match(/Lorem ipsum/, response.body)
    assert_no_match(/eiusmod tempor/, response.body, "Knowhow muss truncated sein (60 Zeichen)")
  end

  test "F43 New-Form zeigt knowhow- und notes-Felder" do
    sign_in_as(@caretaker)
    get new_parent_path
    assert_response :success
    assert_match(/name="user\[knowhow\]"/, response.body)
    assert_match(/name="user\[notes\]"/, response.body)
  end

  # F61: Excel-Export-Action für Eltern-Liste
  test "F61 Caretaker erhält .xlsx als Download" do
    sign_in_as(@caretaker)
    get parents_path(format: :xlsx)
    assert_response :success
    assert_equal Mime[:xlsx].to_s, response.media_type
    assert_match(/mikiwa_eltern_\d{4}-\d{2}-\d{2}\.xlsx/, response.headers["Content-Disposition"])
    assert response.body.bytesize.positive?
  end

  test "F61 Parent bekommt 403 bei /parents.xlsx" do
    sign_in_as(@parent)
    get parents_path(format: :xlsx)
    assert_response :forbidden
  end

  test "F61 unauthenticated user wird auf Login geleitet bei .xlsx" do
    get parents_path(format: :xlsx)
    assert_redirected_to new_session_path
  end

  test "F61 Excel respektiert q-Search-Filter" do
    sign_in_as(@caretaker)
    User.create!(email: "fritz.f61@test.at", password: SecureRandom.hex(20), role: "parent",
                 first_name: "Fritz", last_name: "Müllerschön", phone: "0650 111 222")
    get parents_path(format: :xlsx, q: "Müllerschön")
    assert_response :success
  end

  test "F61 Index-Header enthält Excel-Export-Link" do
    sign_in_as(@caretaker)
    get parents_path
    assert_response :success
    assert_match(/Excel exportieren/, response.body)
    assert_select 'a[href*=".xlsx"]'
  end
end
