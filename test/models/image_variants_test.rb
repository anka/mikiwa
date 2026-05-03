require "test_helper"

class ImageVariantsTest < ActiveSupport::TestCase
  # TS-016-S01: Drei Varianten sind konfiguriert
  test "TS-016 VARIANT_CONFIGS definiert thumb, display und original" do
    assert_includes ImageAttachable::VARIANT_CONFIGS.keys, :thumb
    assert_includes ImageAttachable::VARIANT_CONFIGS.keys, :display
    assert_includes ImageAttachable::VARIANT_CONFIGS.keys, :original
  end

  test "TS-016 thumb-Variante ist als WebP mit Größenbeschränkung konfiguriert" do
    config = ImageAttachable::VARIANT_CONFIGS[:thumb]

    assert_equal :webp, config[:format]
    assert config[:resize_to_limit].present?
    assert_equal [ 300, 300 ], config[:resize_to_limit]
  end

  test "TS-016 display-Variante ist als WebP mit Größenbeschränkung konfiguriert" do
    config = ImageAttachable::VARIANT_CONFIGS[:display]

    assert_equal :webp, config[:format]
    assert config[:resize_to_limit].present?
    assert_equal [ 1600, 1600 ], config[:resize_to_limit]
  end

  test "TS-016 original-Variante hat EXIF-Strip aktiviert" do
    config = ImageAttachable::VARIANT_CONFIGS[:original]

    assert_equal true, config[:strip]
    assert_equal [ 4000, 4000 ], config[:resize_to_limit]
  end
end
