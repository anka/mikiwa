require "test_helper"

class MedizinischerHinweisTest < ActiveSupport::TestCase
  setup do
    @gruppe = Gruppe.create!(name: "Bären")
    @kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @kind = Kind.create!(
      vorname: "Lena", nachname: "Müller",
      geburtsdatum: Date.new(2022, 3, 15),
      gruppe: @gruppe, kindergartenjahr: @kgj,
      foto_einwilligung: false
    )
  end

  test "Medizinischer Hinweis wird gespeichert" do
    mh = MedizinischerHinweis.create!(kind: @kind, hinweis_typ: "allergie", inhalt: "Erdnussallergie")
    assert mh.persisted?
    assert_equal "Erdnussallergie", MedizinischerHinweis.find(mh.id).inhalt
  end

  test "Verschlüsselung: inhalt ist at-rest verschlüsselt" do
    mh = MedizinischerHinweis.create!(kind: @kind, hinweis_typ: "allergie", inhalt: "Erdnussallergie")
    raw = ActiveRecord::Base.connection.exec_query(
      "SELECT inhalt FROM medizinische_hinweise WHERE id = '#{mh.id}'"
    ).first["inhalt"]
    assert_not_equal "Erdnussallergie", raw
  end

  test "Ungültiger hinweis_typ wird abgelehnt" do
    mh = MedizinischerHinweis.new(kind: @kind, hinweis_typ: "sonstiges", inhalt: "Test")
    assert_not mh.valid?
    assert mh.errors[:hinweis_typ].any?
  end

  test "Pflichtfelder: hinweis_typ und inhalt" do
    mh = MedizinischerHinweis.new(kind: @kind)
    assert_not mh.valid?
    assert mh.errors[:hinweis_typ].any?
    assert mh.errors[:inhalt].any?
  end

  test "Alle gültigen Typen werden akzeptiert" do
    %w[allergie medikament besonderheit].each do |typ|
      mh = MedizinischerHinweis.new(kind: @kind, hinweis_typ: typ, inhalt: "Test")
      assert mh.valid?, "Typ '#{typ}' sollte gültig sein"
    end
  end
end
