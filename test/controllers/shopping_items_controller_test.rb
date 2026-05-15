require "test_helper"

# Tests the dedicated ShoppingItemsController used by the Hotwire-driven
# editor – items are created/updated/deleted independently of the list, with
# Turbo Stream responses powering the live editor UI.
class ShoppingItemsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper
  setup do
    @caretaker = User.create!(email: "betreuer_si@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_si@mikiwa.at",   password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @stranger  = User.create!(email: "fremd_si@mikiwa.at",    password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @year = KindergartenYear.create!(
      label: "KGJ SI 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group       = Group.create!(name: "SI-Bären")
    @other_group = Group.create!(name: "SI-Löwen")

    @child = Child.create!(
      first_name: "Anna", last_name: "Schmidt",
      date_of_birth: Date.new(2021, 9, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = ShoppingList.create!(
      title: "Backliste",
      event_date: Date.new(2026, 6, 20),
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
  end

  # --- create ---

  test "caretaker creates item via turbo_stream and gets streams back" do
    sign_in_as(@caretaker)
    assert_difference "@list.shopping_items.count", 1 do
      post shopping_list_shopping_items_path(@list),
           params: { shopping_item: { name: "Hefe", quantity: "1 Würfel" } },
           as: :turbo_stream
    end
    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert_match "shopping_items", response.body
    assert_match "new_shopping_item", response.body
    assert_match "shopping_items_summary", response.body
  end

  test "create assigns increasing positions" do
    sign_in_as(@caretaker)
    post shopping_list_shopping_items_path(@list), params: { shopping_item: { name: "A" } }, as: :turbo_stream
    post shopping_list_shopping_items_path(@list), params: { shopping_item: { name: "B" } }, as: :turbo_stream
    positions = @list.shopping_items.order(:position).pluck(:position)
    assert_equal [ 0, 1 ], positions
  end

  test "create with photo attaches file" do
    sign_in_as(@caretaker)
    file = fixture_file_upload("test.jpg", "image/jpeg")
    post shopping_list_shopping_items_path(@list),
         params: { shopping_item: { name: "Erdbeeren", photo: file } },
         as: :turbo_stream
    assert_response :success
    assert @list.shopping_items.last.photo.attached?
  end

  test "create with blank name renders form with errors" do
    sign_in_as(@caretaker)
    assert_no_difference "@list.shopping_items.count" do
      post shopping_list_shopping_items_path(@list),
           params: { shopping_item: { name: "" } },
           as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "parent cannot create item (403)" do
    sign_in_as(@parent)
    post shopping_list_shopping_items_path(@list), params: { shopping_item: { name: "X" } }
    assert_response :forbidden
  end

  # --- update ---

  test "caretaker updates item inline" do
    item = @list.shopping_items.create!(name: "Mehl", quantity: "500g")
    sign_in_as(@caretaker)
    patch shopping_list_shopping_item_path(@list, item),
          params: { shopping_item: { quantity: "1kg", note: "Type 405" } },
          as: :turbo_stream
    assert_response :success
    item.reload
    assert_equal "1kg", item.quantity
    assert_equal "Type 405", item.note
  end

  # F78: Kategorie inline editieren
  test "F78 caretaker kann Kategorie eines bestehenden Items inline aktualisieren" do
    item = @list.shopping_items.create!(name: "Joghurt", category: "dairy")
    sign_in_as(@caretaker)
    patch shopping_list_shopping_item_path(@list, item),
          params: { shopping_item: { category: "fruit" } },
          as: :turbo_stream
    assert_response :success
    assert_equal "fruit", item.reload.category
  end

  test "F78 ungültige Kategorie → 422; Item bleibt unverändert" do
    item = @list.shopping_items.create!(name: "Joghurt", category: "dairy")
    sign_in_as(@caretaker)
    patch shopping_list_shopping_item_path(@list, item),
          params: { shopping_item: { category: "ungueltig" } },
          as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal "dairy", item.reload.category
  end

  test "purge_photo removes the attachment" do
    item = @list.shopping_items.create!(name: "Erdbeeren")
    item.photo.attach(io: File.open(Rails.root.join("test/fixtures/files/test.jpg")),
                       filename: "test.jpg", content_type: "image/jpeg")
    assert item.reload.photo.attached?

    sign_in_as(@caretaker)
    delete purge_photo_shopping_list_shopping_item_path(@list, item), as: :turbo_stream
    assert_response :success
    perform_enqueued_jobs
    assert_not item.reload.photo.attached?
  end

  # --- destroy ---

  test "caretaker destroys item via turbo_stream" do
    item = @list.shopping_items.create!(name: "Wegwerf")
    sign_in_as(@caretaker)
    assert_difference "ShoppingItem.count", -1 do
      delete shopping_list_shopping_item_path(@list, item), as: :turbo_stream
    end
    assert_response :success
    assert_match "shopping_items_summary", response.body
  end

  # --- complete / uncomplete ---

  test "parent of group can complete item" do
    item = @list.shopping_items.create!(name: "Eier")
    sign_in_as(@parent)
    patch complete_shopping_list_shopping_item_path(@list, item)
    assert_redirected_to shopping_list_path(@list)
    assert item.reload.done?
    assert_equal @parent.id, item.completed_by_id
  end

  test "parent outside group cannot complete item (403)" do
    item = @list.shopping_items.create!(name: "Eier")
    sign_in_as(@stranger)
    patch complete_shopping_list_shopping_item_path(@list, item)
    assert_response :forbidden
  end

  test "complete via turbo_stream returns streams" do
    item = @list.shopping_items.create!(name: "Eier")
    sign_in_as(@parent)
    patch complete_shopping_list_shopping_item_path(@list, item), as: :turbo_stream
    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert_match dom_id(item), response.body
    assert_match "shopping_items_summary", response.body
  end
end
