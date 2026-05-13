require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  setup do
    @group     = Group.create!(name: "Einkauf-Bären")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "betreuer_sl@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_sl@mikiwa.at",   password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")

    @list = ShoppingList.new(
      title: "Waldtag-Einkauf",
      event_date: Date.new(2026, 6, 20),
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @list.shopping_items.build(name: "2 kg Mehl")
    @list.shopping_items.build(name: "Saft", quantity: "10 l")
  end

  test "valid list can be saved" do
    assert @list.save, @list.errors.full_messages.inspect
  end

  test "title is required" do
    @list.title = nil
    assert_not @list.save
    assert @list.errors[:title].any?
  end

  test "uses UUID primary key" do
    @list.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @list.id)
  end

  test "items can be marked as done" do
    @list.save!
    item = @list.shopping_items.first
    item.complete!(@parent)
    assert item.done?
    assert_equal @parent, item.completed_by
    assert item.completed_at.present?
  end

  test "done status can be undone" do
    @list.save!
    item = @list.shopping_items.first
    item.complete!(@parent)
    item.uncomplete!
    assert_not item.done?
    assert_nil item.completed_by_id
  end

  test "open scope returns only non-done items" do
    @list.save!
    item = @list.shopping_items.first
    item.complete!(@parent)
    open_items = @list.shopping_items.open
    assert_not_includes open_items, item
    assert_includes open_items, @list.shopping_items.last
  end

  # F25: Einkaufsliste optional einer Gruppe zuordnen
  test "F25 ShoppingList kann ohne Gruppe gespeichert werden (Kindergarten-weit)" do
    @list.group = nil
    assert @list.save, @list.errors.full_messages.inspect
    assert_nil @list.reload.group_id
  end

  test "F25 ShoppingList mit Gruppe lädt belongs_to korrekt" do
    @list.save!
    assert_equal @group, @list.reload.group
  end

  # F26: Einkaufsliste optional einem Elternteil zuordnen
  test "F26 ShoppingList kann assigned_to setzen und laden" do
    @list.assigned_to = @parent
    assert @list.save, @list.errors.full_messages.inspect
    assert_equal @parent, @list.reload.assigned_to
  end

  test "F26 ShoppingList ohne assigned_to bleibt valid" do
    @list.assigned_to = nil
    assert @list.save
    assert_nil @list.reload.assigned_to
  end
end
