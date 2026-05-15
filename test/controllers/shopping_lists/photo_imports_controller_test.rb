require "test_helper"

class ShoppingLists::PhotoImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_pic@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_pic@mikiwa.at",   password: SecureRandom.hex(20),    role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 111 222")
    @year      = KindergartenYear.create!(
      label: "PIC-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "PIC-Bären")
    @list  = ShoppingList.create!(
      title: "Foto-Liste", event_date: Date.new(2026, 6, 10),
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
    @existing_item = @list.shopping_items.create!(name: "Bestand", category: "dairy", position: 0)
  end

  teardown do
    ENV.delete("OPENAI_API_KEY")
  end

  # --- POST /shopping_lists/photo_imports (neue Liste) ---

  test "F80 Caretaker erstellt neue Liste aus Foto" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    stub_recognizer([
      { name: "Milch", category: :dairy, note: nil },
      { name: "Äpfel", category: :fruit, note: nil }
    ]) do
      sign_in_as(@caretaker)
      assert_difference -> { ShoppingList.count } => 1, -> { ShoppingItem.count } => 2 do
        post shopping_lists_photo_imports_path, params: { image: upload_fixture }
      end
      list = ShoppingList.order(:created_at).last
      assert_redirected_to shopping_list_path(list)
      assert_match(/2 Items erkannt/i, flash[:notice].to_s)
      categories = list.shopping_items.order(:position).pluck(:name, :category)
      assert_equal [ [ "Milch", "dairy" ], [ "Äpfel", "fruit" ] ], categories
    end
  end

  test "F80 Neue Liste erbt KindergartenYear und created_by" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    stub_recognizer([ { name: "Brot", category: :bakery, note: nil } ]) do
      sign_in_as(@caretaker)
      post shopping_lists_photo_imports_path, params: { image: upload_fixture }
      list = ShoppingList.order(:created_at).last
      assert_equal @caretaker.id, list.created_by_id
      assert_equal @year.id,      list.kindergarten_year_id
    end
  end

  # --- POST /shopping_lists/:id/photo_imports (bestehende Liste ergänzen) ---

  test "F80 Bestehende Liste wird ergänzt – alte Items bleiben unverändert" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    stub_recognizer([
      { name: "Brot", category: :bakery, note: nil },
      { name: "Käse", category: :dairy, note: nil }
    ]) do
      sign_in_as(@caretaker)
      assert_difference -> { @list.shopping_items.count } => 2 do
        post shopping_list_photo_imports_path(@list), params: { image: upload_fixture }
      end
      assert_redirected_to shopping_list_path(@list)
      @existing_item.reload
      assert_equal "Bestand", @existing_item.name
      assert_equal "dairy",   @existing_item.category
      names = @list.shopping_items.order(:position).pluck(:name)
      assert_includes names, "Brot"
      assert_includes names, "Käse"
    end
  end

  test "F80 Items werden mit erkannter Kategorie persistiert, NICHT als 'auto'" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    stub_recognizer([ { name: "Joghurt", category: :dairy, note: nil } ]) do
      sign_in_as(@caretaker)
      assert_no_enqueued_jobs only: ShoppingItems::ClassifyJob do
        post shopping_list_photo_imports_path(@list), params: { image: upload_fixture }
      end
      item = @list.shopping_items.find_by(name: "Joghurt")
      assert_equal "dairy", item.category
    end
  end

  # --- Fehlerfälle ---

  test "F80 Eltern bekommt 403 (Authorization)" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    sign_in_as(@parent)
    post shopping_lists_photo_imports_path, params: { image: upload_fixture }
    assert_response :forbidden
  end

  test "F80 Eltern bekommt 403 auch beim Ergänzen-Endpoint" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    sign_in_as(@parent)
    post shopping_list_photo_imports_path(@list), params: { image: upload_fixture }
    assert_response :forbidden
  end

  test "F80 Fehlender API-Key liefert Flash + 422, keine Items" do
    ENV.delete("OPENAI_API_KEY")
    sign_in_as(@caretaker)
    assert_no_difference "ShoppingItem.count" do
      post shopping_list_photo_imports_path(@list), params: { image: upload_fixture }
    end
    assert_response :unprocessable_entity
    assert_match(/derzeit deaktiviert/i, flash[:alert].to_s)
  end

  test "F80 Leeres Erkennungs-Ergebnis: Flash + keine Items, bestehende Liste unverändert" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    stub_recognizer([]) do
      sign_in_as(@caretaker)
      assert_no_difference "ShoppingItem.count" do
        post shopping_list_photo_imports_path(@list), params: { image: upload_fixture }
      end
      assert_match(/keine Items erkennen/i, flash[:alert].to_s)
    end
  end

  test "F80 Leeres Erkennungs-Ergebnis auf neuer Liste: leere Liste bleibt bestehen" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    stub_recognizer([]) do
      sign_in_as(@caretaker)
      assert_difference -> { ShoppingList.count } => 1, -> { ShoppingItem.count } => 0 do
        post shopping_lists_photo_imports_path, params: { image: upload_fixture }
      end
      assert_match(/keine Items erkennen/i, flash[:alert].to_s)
    end
  end

  test "F80 HTTP-Fehler vom Service: Flash + keine Items (Transaktion gerollt)" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    raise_lambda = ->(*_args, **_kwargs) { raise "OpenAI HTTP 500: boom" }
    stub_recognizer_call(raise_lambda) do
      sign_in_as(@caretaker)
      assert_no_difference "ShoppingItem.count" do
        post shopping_list_photo_imports_path(@list), params: { image: upload_fixture }
      end
      assert_match(/fehlgeschlagen/i, flash[:alert].to_s)
    end
  end

  test "F80 Fehlende Bild-Datei liefert 422 mit Flash" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    sign_in_as(@caretaker)
    post shopping_list_photo_imports_path(@list), params: {}
    assert_response :unprocessable_entity
    assert_match(/Foto/i, flash[:alert].to_s)
  end

  private

  def upload_fixture
    Rack::Test::UploadedFile.new(
      StringIO.new("fake-jpeg-bytes"),
      "image/jpeg",
      original_filename: "list.jpg"
    )
  end

  def stub_recognizer(items, &block)
    stub_recognizer_call(->(*_args, **_kwargs) { items }, &block)
  end

  def stub_recognizer_call(replacement)
    target  = ShoppingItems::ImageRecognizer
    sclass  = target.singleton_class
    backup  = sclass.instance_method(:call)
    target.define_singleton_method(:call) { |*args, **kwargs| replacement.call(*args, **kwargs) }
    yield
  ensure
    sclass.define_method(:call, backup)
  end
end
