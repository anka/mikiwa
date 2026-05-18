require "test_helper"

class ShoppingItemTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @group = Group.create!(name: "SI-Gruppe")
    @year = KindergartenYear.create!(label: "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true)
    @user = User.create!(email: "si_user@mikiwa.at", password: SecureRandom.hex(20), role: "caretaker")
    @list = ShoppingList.create!(title: "SI-Liste", event_date: Date.current,
      group: @group, kindergarten_year: @year, created_by: @user)
  end

  test "F51 category accepts all defined enum values" do
    ShoppingItem::CATEGORY_ORDER.each do |key|
      item = @list.shopping_items.create!(name: "Test #{key}", category: key)
      assert_equal key, item.reload.category
    end
  end

  test "F51 category is optional (NULL allowed)" do
    item = @list.shopping_items.create!(name: "Brot")
    assert_nil item.category
  end

  test "F51 invalides Enum-Update wirft ArgumentError" do
    item = @list.shopping_items.create!(name: "Brot")
    assert_raises ArgumentError do
      item.update!(category: "unknown_value")
    end
  end

  test "F51 CATEGORY_ORDER definiert genau 12 Werte" do
    assert_equal 12, ShoppingItem::CATEGORY_ORDER.size
  end

  # F79: 'auto'-Enum + after_commit-Hook
  test "F79 category 'auto' ist als Enum-Wert erlaubt" do
    item = @list.shopping_items.create!(name: "Brot", category: "auto")
    assert_equal "auto", item.reload.category
    assert item.category_auto?
  end

  test "F79 CATEGORY_ORDER enthält 'auto' NICHT (Reihenfolge unverändert)" do
    assert_not_includes ShoppingItem::CATEGORY_ORDER, "auto"
  end

  test "F79 after_commit enqueued ClassifyJob bei category=auto + enabled?" do
    with_stub(ShoppingItems::AutoClassifier, :api_key, "sk-test") do
      assert_enqueued_with(job: ShoppingItems::ClassifyJob) do
        @list.shopping_items.create!(name: "Brot", category: "auto")
      end
    end
  end

  test "F79 kein Job bei category != auto" do
    with_stub(ShoppingItems::AutoClassifier, :api_key, "sk-test") do
      assert_no_enqueued_jobs only: ShoppingItems::ClassifyJob do
        @list.shopping_items.create!(name: "Apfel", category: "fruit")
      end
    end
  end

  test "F79 kein Job wenn API-Key fehlt" do
    assert_no_enqueued_jobs only: ShoppingItems::ClassifyJob do
      @list.shopping_items.create!(name: "Brot", category: "auto")
    end
  end
end
