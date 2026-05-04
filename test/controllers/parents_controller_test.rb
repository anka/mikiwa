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
    other = User.create!(email: "andere_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
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
                 role: "parent", first_name: "Felix", last_name: "Schmidt")
    User.create!(email: "gerda@test.at", password: SecureRandom.hex(20),
                 role: "parent", first_name: "Gerda", last_name: "Bauer")

    get parents_path, params: { q: "Felix" }
    assert_response :success
    assert_match "Felix", response.body
    assert_no_match "Gerda", response.body
  end

  test "F20 Eltern-Liste filtert nach E-Mail" do
    sign_in_as(@caretaker)
    User.create!(email: "felix@test.at", password: SecureRandom.hex(20),
                 role: "parent", first_name: "Felix", last_name: "Schmidt")

    get parents_path, params: { q: "felix@test" }
    assert_response :success
    assert_match "Felix", response.body
  end
end
