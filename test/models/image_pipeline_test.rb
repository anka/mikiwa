require "test_helper"

class ImagePipelineTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  # Helper: create a test JPEG fixture
  def jpeg_file(size_mb: 1)
    # Create a minimal valid JPEG
    file = Tempfile.new([ "test_image", ".jpg" ])
    file.write("\xFF\xD8\xFF\xE0" + "\x00" * (size_mb * 1_048_576))
    file.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: "test.jpg",
      type: "image/jpeg"
    )
  end

  def gif_file
    file = Tempfile.new([ "test_gif", ".gif" ])
    file.write("GIF89a\x01\x00\x01\x00\x00\xff\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x00;")
    file.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: "test.gif",
      type: "image/gif"
    )
  end

  test "ImageAttachable-Concern existiert und definiert erlaubte Formate" do
    assert defined?(ImageAttachable)
    assert_includes ImageAttachable::ALLOWED_TYPES, "image/jpeg"
    assert_includes ImageAttachable::ALLOWED_TYPES, "image/png"
    assert_includes ImageAttachable::ALLOWED_TYPES, "image/webp"
    assert_includes ImageAttachable::ALLOWED_TYPES, "image/heic"
  end

  test "Maximale Dateigröße ist 10 MB (F29)" do
    assert_equal 10, ImageAttachable::MAX_SIZE_BYTES / 1_048_576
    assert_equal 10, ImageAttachable::MAX_SIZE_MB
  end

  test "GIF-Format ist nicht in der Erlaubt-Liste" do
    assert_not_includes ImageAttachable::ALLOWED_TYPES, "image/gif"
  end
end
