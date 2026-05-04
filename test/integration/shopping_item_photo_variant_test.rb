require "test_helper"

# Verifies that the photo variant pipeline (MiniMagick) actually produces a
# bytestream – guards against the libvips/MiniMagick processor mismatch that
# crashes the show page when libvips is not installed system-wide.
class ShoppingItemPhotoVariantTest < ActiveSupport::TestCase
  test "thumb variant processes successfully with configured processor" do
    list = ShoppingList.create!(
      title: "Variant-Test",
      event_date: Date.current + 7,
      group: Group.create!(name: "Variant-Bären"),
      kindergarten_year: KindergartenYear.create!(
        label: "VT 2025/26",
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 7, 31),
        active: false
      ),
      created_by: User.create!(email: "var_betreuer@mikiwa.at",
                                password: "sicherespasswort1234",
                                role: "caretaker")
    )
    item = list.shopping_items.create!(name: "Erdbeeren")
    item.photo.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample_photo.jpg")),
      filename: "sample_photo.jpg",
      content_type: "image/jpeg"
    )

    variant = item.photo.variant(:thumb).processed
    assert variant.image.attached?, "thumb variant must materialize an attachment"
  ensure
    list&.destroy
  end
end
