require "test_helper"

class NotfallkontakteControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_nk@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_nk@mikiwa.at",  password: SecureRandom.hex(20), role: "parent")
    @other_parent = User.create!(email: "other_nk@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @gruppe    = Gruppe.create!(name: "Sterne")
    @kgj       = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @kind = Kind.create!(
      vorname: "Tom", nachname: "Klein",
      geburtsdatum: Date.new(2021, 4, 1),
      gruppe: @gruppe, kindergartenjahr: @kgj,
      foto_einwilligung: true
    )
    ElternKind.create!(user: @parent, kind: @kind)
    @nk = Notfallkontakt.create!(kind: @kind, name: "Anna Klein", beziehung: "Mutter", telefon: "+43 664 999", position: 1)
  end

  test "Betreuer kann Notfallkontakt anlegen" do
    sign_in_as(@caretaker)
    assert_difference "Notfallkontakt.count", 1 do
      post kinder_notfallkontakte_path(@kind), params: {
        notfallkontakt: { name: "Opa", beziehung: "Großvater", telefon: "+43 650 123", position: 2 }
      }
    end
    assert_redirected_to kinder_path(@kind)
  end

  test "Elternteil kann Notfallkontakt für eigenes Kind anlegen" do
    sign_in_as(@parent)
    assert_difference "Notfallkontakt.count", 1 do
      post kinder_notfallkontakte_path(@kind), params: {
        notfallkontakt: { name: "Opa", beziehung: "Großvater", telefon: "+43 650 123", position: 2 }
      }
    end
    assert_redirected_to kinder_path(@kind)
  end

  test "Elternteil hat keinen Zugriff auf fremdes Kind (403)" do
    sign_in_as(@other_parent)
    post kinder_notfallkontakte_path(@kind), params: {
      notfallkontakt: { name: "X", beziehung: "X", telefon: "X", position: 1 }
    }
    assert_response :forbidden
  end

  test "Ungültige Daten ergeben Fehler-Render" do
    sign_in_as(@caretaker)
    assert_no_difference "Notfallkontakt.count" do
      post kinder_notfallkontakte_path(@kind), params: {
        notfallkontakt: { name: "", beziehung: "", telefon: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "Betreuer kann Notfallkontakt aktualisieren" do
    sign_in_as(@caretaker)
    patch kinder_notfallkontakt_path(@kind, @nk), params: {
      notfallkontakt: { name: "Anna K. (aktualisiert)" }
    }
    assert_redirected_to kinder_path(@kind)
    assert_equal "Anna K. (aktualisiert)", @nk.reload.name
  end

  test "Betreuer kann Notfallkontakt löschen" do
    sign_in_as(@caretaker)
    assert_difference "Notfallkontakt.count", -1 do
      delete kinder_notfallkontakt_path(@kind, @nk)
    end
    assert_redirected_to kinder_path(@kind)
  end
end
