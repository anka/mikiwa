require "test_helper"

class KinderControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_k@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "eltern2@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @gruppe = Gruppe.create!(name: "Löwen")
    @kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @kind = Kind.create!(
      vorname: "Finn",
      nachname: "Berger",
      geburtsdatum: Date.new(2021, 5, 10),
      gruppe: @gruppe,
      kindergartenjahr: @kgj,
      foto_einwilligung: true
    )
    ElternKind.create!(user: @parent, kind: @kind)
  end

  test "Betreuer kann Kinderliste aufrufen" do
    sign_in_as(@caretaker)
    get kinder_index_path
    assert_response :success
  end

  test "Elternteil sieht nur eigene Kinder" do
    sign_in_as(@parent)
    other_kind = Kind.create!(
      vorname: "Julia", nachname: "Stern",
      geburtsdatum: Date.new(2022, 1, 1),
      gruppe: @gruppe, kindergartenjahr: @kgj,
      foto_einwilligung: false
    )
    get kinder_index_path
    assert_match "Finn", response.body
    assert_no_match "Julia", response.body
  end

  test "Betreuer kann Kind anlegen" do
    sign_in_as(@caretaker)
    assert_difference "Kind.count", 1 do
      post kinder_index_path, params: {
        kind: {
          vorname: "Eva", nachname: "Müller",
          geburtsdatum: "2022-04-01",
          gruppe_id: @gruppe.id,
          kindergartenjahr_id: @kgj.id,
          foto_einwilligung: "1"
        }
      }
    end
    assert_redirected_to kinder_index_path
  end

  test "Kind ohne Pflichtfeld wird abgelehnt" do
    sign_in_as(@caretaker)
    assert_no_difference "Kind.count" do
      post kinder_index_path, params: {
        kind: { vorname: "Eva", nachname: "Müller" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "Betreuer kann Kind deaktivieren" do
    sign_in_as(@caretaker)
    patch deaktivieren_kinder_path(@kind)
    assert_not @kind.reload.aktiv?
    assert_redirected_to kinder_index_path
  end

  test "Elternteil kann Kind nicht deaktivieren (403)" do
    sign_in_as(@parent)
    patch deaktivieren_kinder_path(@kind)
    assert_response :forbidden
  end
end
