require "test_helper"

class KindergartenjahreControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin_kgj@mikiwa.at", password: "adminpasswort1234567", role: "admin")
    @caretaker = User.create!(email: "betreuer_kgj@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @aktives_jahr = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @vergangenes_jahr = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2024/25",
      start_datum: Date.new(2024, 9, 1),
      end_datum: Date.new(2025, 7, 31),
      aktiv: false
    )
  end

  test "Betreuer kann Kindergartenjahr-Liste aufrufen" do
    sign_in_as(@caretaker)
    get kindergartenjahre_index_path
    assert_response :success
  end

  test "Neues Kindergartenjahr anlegen" do
    sign_in_as(@caretaker)
    assert_difference "Kindergartenjahr.count", 1 do
      post kindergartenjahre_index_path, params: {
        kindergartenjahr: {
          bezeichnung: "KGJ 2026/27",
          start_datum: "2026-09-01",
          end_datum: "2027-07-31"
        }
      }
    end
    assert_redirected_to kindergartenjahre_index_path
  end

  test "Aktiv-Wechsel deaktiviert vorheriges Jahr" do
    sign_in_as(@caretaker)
    neues_jahr = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2026/27",
      start_datum: Date.new(2026, 9, 1),
      end_datum: Date.new(2027, 7, 31),
      aktiv: false
    )
    patch aktiviere_kindergartenjahre_path(neues_jahr)
    assert neues_jahr.reload.aktiv?
    assert_not @aktives_jahr.reload.aktiv?
  end

  test "Betreuer sieht alle Kindergartenjahre" do
    sign_in_as(@caretaker)
    get kindergartenjahre_index_path
    assert_match @aktives_jahr.bezeichnung, response.body
    assert_match @vergangenes_jahr.bezeichnung, response.body
  end

  test "Jahresübergang durchführen (ohne Kinder)" do
    sign_in_as(@caretaker)
    neues_jahr = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2026/27",
      start_datum: Date.new(2026, 9, 1),
      end_datum: Date.new(2027, 7, 31),
      aktiv: false
    )
    post jahresubergang_durchfuehren_kindergartenjahre_path(neues_jahr), params: { kind_ids: [] }
    assert neues_jahr.reload.aktiv?
    assert_redirected_to kindergartenjahre_index_path
  end

  test "Jahresübergang-Formular ist für Betreuer erreichbar" do
    sign_in_as(@caretaker)
    neues_jahr = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2026/27",
      start_datum: Date.new(2026, 9, 1),
      end_datum: Date.new(2027, 7, 31),
      aktiv: false
    )
    get jahresubergang_kindergartenjahre_path(neues_jahr)
    assert_response :success
  end
end
