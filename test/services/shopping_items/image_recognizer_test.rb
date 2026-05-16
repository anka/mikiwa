require "test_helper"
require "stringio"

class ShoppingItems::ImageRecognizerTest < ActiveSupport::TestCase
  setup do
    @png_io = StringIO.new("fake-png-bytes")
  end

  test "F80 enabled? false ohne OPENAI_API_KEY" do
    ENV.delete("OPENAI_API_KEY")
    assert_not ShoppingItems::ImageRecognizer.enabled?
  end

  test "F80 enabled? true mit OPENAI_API_KEY" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    assert ShoppingItems::ImageRecognizer.enabled?
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call gibt Array von Items mit gültigen Kategorien zurück" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    recognizer = ShoppingItems::ImageRecognizer.new(@png_io)
    payload = openai_response([
      { name: "Milch", category: "dairy", quantity: "2 Liter", note: nil },
      { name: "Äpfel", category: "fruit", quantity: nil,       note: "bio" }
    ])
    with_stub(recognizer, :fetch_completion, payload) do
      result = recognizer.call
      assert_equal 2, result.size
      assert_equal "Milch",   result[0][:name]
      assert_equal :dairy,    result[0][:category]
      assert_equal "2 Liter", result[0][:quantity]
      assert_nil   result[0][:note]
      assert_equal "Äpfel",   result[1][:name]
      assert_equal :fruit,    result[1][:category]
      assert_nil   result[1][:quantity]
      assert_equal "bio",     result[1][:note]
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call mappt unbekannte Kategorie auf :other" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    recognizer = ShoppingItems::ImageRecognizer.new(@png_io)
    payload = openai_response([ { name: "Mystery", category: "random_unknown", quantity: nil, note: nil } ])
    with_stub(recognizer, :fetch_completion, payload) do
      result = recognizer.call
      assert_equal 1, result.size
      assert_equal :other, result[0][:category]
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call gibt leeres Array bei leeren items zurück" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    recognizer = ShoppingItems::ImageRecognizer.new(@png_io)
    payload = openai_response([])
    with_stub(recognizer, :fetch_completion, payload) do
      assert_equal [], recognizer.call
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call gibt leeres Array bei ungültigem JSON zurück" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    recognizer = ShoppingItems::ImageRecognizer.new(@png_io)
    bad_payload = { "choices" => [ { "message" => { "content" => "kein JSON" } } ] }
    with_stub(recognizer, :fetch_completion, bad_payload) do
      assert_equal [], recognizer.call
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call filtert Items ohne Namen heraus" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    recognizer = ShoppingItems::ImageRecognizer.new(@png_io)
    payload = openai_response([
      { name: "",     category: "dairy",  quantity: nil, note: nil },
      { name: "Brot", category: "bakery", quantity: nil, note: nil }
    ])
    with_stub(recognizer, :fetch_completion, payload) do
      result = recognizer.call
      assert_equal 1, result.size
      assert_equal "Brot", result[0][:name]
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call gibt nil für quantity zurück wenn leerer String" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    recognizer = ShoppingItems::ImageRecognizer.new(@png_io)
    payload = openai_response([ { name: "Brot", category: "bakery", quantity: "   ", note: nil } ])
    with_stub(recognizer, :fetch_completion, payload) do
      result = recognizer.call
      assert_nil result[0][:quantity]
    end
  ensure
    ENV.delete("OPENAI_API_KEY")
  end

  test "F80 call raised ohne API-Key" do
    ENV.delete("OPENAI_API_KEY")
    assert_raises(RuntimeError) { ShoppingItems::ImageRecognizer.new(@png_io).call }
  end

  private

  def openai_response(items)
    {
      "choices" => [
        { "message" => { "content" => { items: items }.to_json } }
      ]
    }
  end
end
