require "test_helper"

class KindergartenjährTest < ActiveSupport::TestCase
  def valid_attributes(overrides = {})
    {
      bezeichnung: "KGJ 2025/26",
      start_datum: Date.new(2025, 9, 1),
      end_datum: Date.new(2026, 7, 31),
      aktiv: false
    }.merge(overrides)
  end

  test "hat UUID als Primärschlüssel" do
    kgj = Kindergartenjahr.create!(valid_attributes)
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, kgj.id)
  end

  test "hat created_at und updated_at Timestamps" do
    kgj = Kindergartenjahr.create!(valid_attributes)
    assert_not_nil kgj.created_at
    assert_not_nil kgj.updated_at
  end

  test "hat frei konfigurierbares Start- und Enddatum" do
    kgj = Kindergartenjahr.create!(valid_attributes(start_datum: Date.new(2024, 8, 15), end_datum: Date.new(2025, 6, 30)))
    assert_equal Date.new(2024, 8, 15), kgj.start_datum
    assert_equal Date.new(2025, 6, 30), kgj.end_datum
  end

  test "aktives Kindergartenjahr – Einzigartigkeit: zweites Aktivieren deaktiviert erstes" do
    kgj1 = Kindergartenjahr.create!(valid_attributes(bezeichnung: "KGJ 2024/25", aktiv: true))
    assert kgj1.aktiv?

    kgj2 = Kindergartenjahr.create!(valid_attributes(bezeichnung: "KGJ 2025/26", aktiv: true))
    assert kgj2.aktiv?

    kgj1.reload
    assert_not kgj1.aktiv?, "Erstes Jahr muss deaktiviert werden wenn zweites aktiv wird"
  end

  test "genau ein aktives Kindergartenjahr gleichzeitig" do
    Kindergartenjahr.create!(valid_attributes(bezeichnung: "KGJ A", aktiv: true))
    Kindergartenjahr.create!(valid_attributes(bezeichnung: "KGJ B", aktiv: true))
    Kindergartenjahr.create!(valid_attributes(bezeichnung: "KGJ C", aktiv: true))

    aktive_jahre = Kindergartenjahr.where(aktiv: true)
    assert_equal 1, aktive_jahre.count
  end

  test "bezeichnung ist Pflichtfeld" do
    kgj = Kindergartenjahr.new(valid_attributes.except(:bezeichnung))
    assert_not kgj.valid?
    assert_includes kgj.errors[:bezeichnung], "muss ausgefüllt werden"
  end

  test "start_datum ist Pflichtfeld" do
    kgj = Kindergartenjahr.new(valid_attributes.except(:start_datum))
    assert_not kgj.valid?
  end

  test "end_datum ist Pflichtfeld" do
    kgj = Kindergartenjahr.new(valid_attributes.except(:end_datum))
    assert_not kgj.valid?
  end
end
