require "test_helper"

class ShoppingItems::AutoClassifierTest < ActiveSupport::TestCase
  setup do
    @year = KindergartenYear.create!(
      label: "AC-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group   = Group.create!(name: "AC-Bären")
    @caretaker = User.create!(email: "ac_betreuer@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @list = ShoppingList.create!(
      title: "AC-Liste", event_date: Date.new(2026, 6, 1),
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
    @item = @list.shopping_items.create!(name: "Äpfel", category: "auto")
  end

  test "F79 enabled? false ohne OPENAI_API_KEY" do
    ENV.delete("OPENAI_API_KEY")
    assert_not ShoppingItems::AutoClassifier.enabled?
  end

  test "F79 enabled? true mit OPENAI_API_KEY" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    assert ShoppingItems::AutoClassifier.enabled?
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F79 call gibt Symbol aus Enum bei valider Response" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    classifier = ShoppingItems::AutoClassifier.new(@item)
    with_stub(classifier, :fetch_completion, openai_response("fruit")) do
      assert_equal :fruit, classifier.call
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F79 call mappt unbekannten Enum-Wert auf :other" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    classifier = ShoppingItems::AutoClassifier.new(@item)
    with_stub(classifier, :fetch_completion, openai_response("random_unknown")) do
      assert_equal :other, classifier.call
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F79 call fängt ungültiges JSON ab und liefert :other" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    classifier = ShoppingItems::AutoClassifier.new(@item)
    bad_payload = { "choices" => [ { "message" => { "content" => "kein JSON" } } ] }
    with_stub(classifier, :fetch_completion, bad_payload) do
      assert_equal :other, classifier.call
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F79 call raised ohne API-Key" do
    ENV.delete("OPENAI_API_KEY")
    assert_raises(RuntimeError) { ShoppingItems::AutoClassifier.new(@item).call }
  end

  private

  def openai_response(category)
    { "choices" => [ { "message" => { "content" => { category: category }.to_json } } ] }
  end
end
