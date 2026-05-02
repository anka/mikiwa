require "test_helper"

class GruppeTest < ActiveSupport::TestCase
  test "hat UUID als Primärschlüssel" do
    gruppe = Gruppe.create!(name: "Bären")
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, gruppe.id)
  end

  test "hat created_at und updated_at Timestamps" do
    gruppe = Gruppe.create!(name: "Löwen")
    assert_not_nil gruppe.created_at
    assert_not_nil gruppe.updated_at
  end

  test "updated_at ändert sich nach Aktualisierung, created_at bleibt gleich" do
    gruppe = Gruppe.create!(name: "Tiger")
    original_created_at = gruppe.created_at
    sleep 0.01
    gruppe.update!(name: "Tiger-Gruppe")
    assert_equal original_created_at.to_i, gruppe.created_at.to_i
    assert gruppe.updated_at >= original_created_at
  end

  test "name ist Pflichtfeld" do
    gruppe = Gruppe.new
    assert_not gruppe.valid?
    assert_includes gruppe.errors[:name], "muss ausgefüllt werden"
  end
end
