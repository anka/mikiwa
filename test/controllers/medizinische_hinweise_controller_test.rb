require "test_helper"

class MedizinischeHinweiseControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_mh@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_mh@mikiwa.at",  password: SecureRandom.hex(20), role: "parent")
    @other_parent = User.create!(email: "other_mh@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @gruppe    = Gruppe.create!(name: "Monde")
    @kgj       = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @kind = Kind.create!(
      vorname: "Mia", nachname: "Lang",
      geburtsdatum: Date.new(2022, 7, 20),
      gruppe: @gruppe, kindergartenjahr: @kgj,
      foto_einwilligung: false
    )
    ElternKind.create!(user: @parent, kind: @kind)
    @mh = MedizinischerHinweis.create!(kind: @kind, hinweis_typ: "allergie", inhalt: "Milchallergie")
  end

  test "Betreuer kann medizinischen Hinweis anlegen" do
    sign_in_as(@caretaker)
    assert_difference "MedizinischerHinweis.count", 1 do
      post kinder_medizinische_hinweise_path(@kind), params: {
        medizinischer_hinweis: { hinweis_typ: "medikament", inhalt: "Voltaren Emulgel" }
      }
    end
    assert_redirected_to kinder_path(@kind)
  end

  test "Elternteil kann Hinweis für eigenes Kind anlegen" do
    sign_in_as(@parent)
    assert_difference "MedizinischerHinweis.count", 1 do
      post kinder_medizinische_hinweise_path(@kind), params: {
        medizinischer_hinweis: { hinweis_typ: "besonderheit", inhalt: "Schläft mittags" }
      }
    end
    assert_redirected_to kinder_path(@kind)
  end

  test "Elternteil hat keinen Zugriff auf fremdes Kind (403)" do
    sign_in_as(@other_parent)
    post kinder_medizinische_hinweise_path(@kind), params: {
      medizinischer_hinweis: { hinweis_typ: "allergie", inhalt: "X" }
    }
    assert_response :forbidden
  end

  test "Ungültiger Typ ergibt Fehler-Render" do
    sign_in_as(@caretaker)
    assert_no_difference "MedizinischerHinweis.count" do
      post kinder_medizinische_hinweise_path(@kind), params: {
        medizinischer_hinweis: { hinweis_typ: "ungueltig", inhalt: "X" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "Betreuer kann Hinweis aktualisieren" do
    sign_in_as(@caretaker)
    patch kinder_medizinischer_hinweis_path(@kind, @mh), params: {
      medizinischer_hinweis: { inhalt: "Milchallergie (aktualisiert)" }
    }
    assert_redirected_to kinder_path(@kind)
    assert_equal "Milchallergie (aktualisiert)", @mh.reload.inhalt
  end

  test "Betreuer kann Hinweis löschen" do
    sign_in_as(@caretaker)
    assert_difference "MedizinischerHinweis.count", -1 do
      delete kinder_medizinischer_hinweis_path(@kind, @mh)
    end
    assert_redirected_to kinder_path(@kind)
  end
end
