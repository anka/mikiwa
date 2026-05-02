require "test_helper"

class KindTest < ActiveSupport::TestCase
  setup do
    @gruppe = Gruppe.create!(name: "Bären")
    @kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: true
    )
    @parent = User.create!(email: "eltern_k@test.at", password: SecureRandom.hex(20), role: "parent")
    @kind = Kind.new(
      vorname: "Lena",
      nachname: "Baum",
      geburtsdatum: Date.new(2021, 3, 15),
      gruppe: @gruppe,
      kindergartenjahr: @kgj,
      foto_einwilligung: true
    )
  end

  test "Gültiges Kind kann gespeichert werden" do
    assert @kind.save
  end

  test "Vorname ist Pflichtfeld" do
    @kind.vorname = nil
    assert_not @kind.save
    assert @kind.errors[:vorname].any?
  end

  test "Geburtsdatum ist Pflichtfeld" do
    @kind.geburtsdatum = nil
    assert_not @kind.save
    assert @kind.errors[:geburtsdatum].any?
  end

  test "Foto-Einwilligung muss explizit gesetzt sein" do
    @kind.foto_einwilligung = nil
    assert_not @kind.save
    assert @kind.errors[:foto_einwilligung].any?
  end

  test "Kind ist standardmäßig aktiv" do
    @kind.save!
    assert @kind.aktiv?
  end

  test "deaktivieren! setzt aktiv auf false" do
    @kind.save!
    @kind.deaktivieren!
    assert_not @kind.reload.aktiv?
  end

  test "active scope enthält nur aktive Kinder" do
    @kind.save!
    inaktives_kind = Kind.create!(
      vorname: "Max", nachname: "Wolf",
      geburtsdatum: Date.new(2020, 5, 1),
      gruppe: @gruppe, kindergartenjahr: @kgj,
      foto_einwilligung: false, aktiv: false
    )
    active_ids = Kind.active.pluck(:id)
    assert_includes active_ids, @kind.id
    assert_not_includes active_ids, inaktives_kind.id
  end

  test "anzeigename gibt Rufname wenn vorhanden" do
    @kind.rufname = "Leni"
    assert_equal "Leni", @kind.anzeigename
  end

  test "anzeigename gibt Vorname wenn kein Rufname" do
    assert_equal "Lena", @kind.anzeigename
  end

  test "vollstaendiger_name gibt Vor- und Nachname" do
    @kind.save!
    assert_equal "Lena Baum", @kind.vollstaendiger_name
  end

  test "Elternteil kann Kind zugeordnet werden" do
    @kind.save!
    ElternKind.create!(user: @parent, kind: @kind, bemerkung: "Mama")
    assert_includes @kind.reload.eltern, @parent
    assert_includes @parent.reload.kinder, @kind
  end

  test "uebertragen_in kopiert Kind in neues Jahr" do
    @kind.save!
    ElternKind.create!(user: @parent, kind: @kind)
    neues_kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2026/27",
      start_datum: Date.new(2026, 9, 1),
      end_datum: Date.new(2027, 7, 31),
      aktiv: false
    )
    neues_kind = @kind.uebertragen_in(neues_kgj)
    assert_equal neues_kgj, neues_kind.kindergartenjahr
    assert_includes neues_kind.eltern, @parent
  end

  test "uebertragen_in ist idempotent" do
    @kind.save!
    neues_kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2026/27",
      start_datum: Date.new(2026, 9, 1),
      end_datum: Date.new(2027, 7, 31),
      aktiv: false
    )
    @kind.uebertragen_in(neues_kgj)
    assert_no_difference "Kind.count" do
      @kind.uebertragen_in(neues_kgj)
    end
  end
end
