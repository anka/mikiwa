require "test_helper"

class ShoppingItems::ClassifyJobTest < ActiveJob::TestCase
  setup do
    @year = KindergartenYear.create!(
      label: "CJ-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group     = Group.create!(name: "CJ-Bären")
    @caretaker = User.create!(email: "cj_betreuer@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @list = ShoppingList.create!(
      title: "CJ-Liste", event_date: Date.new(2026, 6, 1),
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
  end

  test "F79 perform aktualisiert Item.category mit Classifier-Resultat" do
    with_stub(ShoppingItems::AutoClassifier, :api_key, "sk-test") do
      item = @list.shopping_items.create!(name: "Äpfel", category: "auto")
      with_stub(ShoppingItems::AutoClassifier, :call, :fruit) do
        ShoppingItems::ClassifyJob.perform_now(item.id)
      end
      assert_equal "fruit", item.reload.category
    end
  end

  test "F79 perform ist no-op wenn Item bereits manuell überschrieben wurde" do
    with_stub(ShoppingItems::AutoClassifier, :api_key, "sk-test") do
      item = @list.shopping_items.create!(name: "Äpfel", category: "auto")
      item.update!(category: "vegetable")
      with_stub(ShoppingItems::AutoClassifier, :call, :fruit) do
        ShoppingItems::ClassifyJob.perform_now(item.id)
      end
      assert_equal "vegetable", item.reload.category
    end
  end

  test "F79 perform ist no-op wenn Item nicht mehr existiert" do
    with_stub(ShoppingItems::AutoClassifier, :api_key, "sk-test") do
      assert_nothing_raised { ShoppingItems::ClassifyJob.perform_now("nicht_existent") }
    end
  end

  test "F79 perform ist no-op wenn API-Key fehlt" do
    item = @list.shopping_items.create!(name: "Äpfel", category: "auto")
    with_stub(ShoppingItems::AutoClassifier, :call, :fruit) do
      ShoppingItems::ClassifyJob.perform_now(item.id)
    end
    assert_equal "auto", item.reload.category
  end
end
