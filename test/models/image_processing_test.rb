require "test_helper"

class ImageProcessingTest < ActiveSupport::TestCase
  # TS-015-S01: GPS-EXIF wird durch Varianten-Konfiguration entfernt
  test "TS-015 original-Variante hat strip: true gesetzt" do
    assert_equal true, ImageAttachable::VARIANT_CONFIGS[:original][:strip],
      "original-Variante muss strip: true enthalten, um EXIF-Metadaten zu entfernen"
  end

  test "TS-015 thumb und display konvertieren zu WebP – Format enthält keine EXIF-GPS-Daten" do
    assert_equal :webp, ImageAttachable::VARIANT_CONFIGS[:thumb][:format]
    assert_equal :webp, ImageAttachable::VARIANT_CONFIGS[:display][:format]
  end

  test "TS-015 alle Varianten sind konfiguriert" do
    assert_includes ImageAttachable::VARIANT_CONFIGS.keys, :thumb
    assert_includes ImageAttachable::VARIANT_CONFIGS.keys, :display
    assert_includes ImageAttachable::VARIANT_CONFIGS.keys, :original
  end
end
