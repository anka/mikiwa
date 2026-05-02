require "test_helper"

class NotfallkontaktTest < ActiveSupport::TestCase
  setup do
    @gruppe = Gruppe.create!(name: "Löwen")
    @kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @kind = Kind.create!(
      vorname: "Finn", nachname: "Berger",
      geburtsdatum: Date.new(2021, 5, 10),
      gruppe: @gruppe, kindergartenjahr: @kgj,
      foto_einwilligung: true
    )
  end

  test "Notfallkontakt wird gespeichert" do
    nk = Notfallkontakt.create!(kind: @kind, name: "Maria Berger", beziehung: "Mutter", telefon: "+43 664 123456", position: 1)
    assert nk.persisted?
    assert_equal "Maria Berger", Notfallkontakt.find(nk.id).name
    assert_equal "+43 664 123456", Notfallkontakt.find(nk.id).telefon
  end

  test "Verschlüsselung: telefon ist at-rest verschlüsselt" do
    nk = Notfallkontakt.create!(kind: @kind, name: "Maria Berger", beziehung: "Mutter", telefon: "+43 664 123456", position: 1)
    raw = ActiveRecord::Base.connection.exec_query(
      "SELECT telefon FROM notfallkontakte WHERE id = '#{nk.id}'"
    ).first["telefon"]
    assert_not_equal "+43 664 123456", raw
  end

  test "Verschlüsselung: name ist at-rest verschlüsselt" do
    nk = Notfallkontakt.create!(kind: @kind, name: "Maria Berger", beziehung: "Mutter", telefon: "+43 664 123456", position: 1)
    raw = ActiveRecord::Base.connection.exec_query(
      "SELECT name FROM notfallkontakte WHERE id = '#{nk.id}'"
    ).first["name"]
    assert_not_equal "Maria Berger", raw
  end

  test "Pflichtfelder: name, telefon, beziehung" do
    nk = Notfallkontakt.new(kind: @kind, position: 1)
    assert_not nk.valid?
    assert nk.errors[:name].any?
    assert nk.errors[:telefon].any?
    assert nk.errors[:beziehung].any?
  end

  test "Sortierung nach position" do
    Notfallkontakt.create!(kind: @kind, name: "Oma", beziehung: "Großmutter", telefon: "111", position: 2)
    Notfallkontakt.create!(kind: @kind, name: "Papa", beziehung: "Vater", telefon: "222", position: 1)
    assert_equal %w[Papa Oma], @kind.notfallkontakte.map(&:name)
  end
end
