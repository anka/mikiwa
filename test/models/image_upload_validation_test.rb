require "test_helper"

class ImageUploadValidationTest < ActiveSupport::TestCase
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Upload-Test-Gruppe")
    @caretaker = User.create!(email: "upload_test@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @gallery = Gallery.new(title: "Upload-Test", kindergarten_year: @year, created_by: @caretaker)
    @gallery.gallery_groups.build(group: @group)
    @gallery.save!
  end

  teardown do
    @gallery.destroy
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-017-S01: Datei über 15 MB wird abgewiesen
  test "TS-017 Bild über 15 MB ist ungültig" do
    photo = Photo.new(gallery: @gallery)
    photo.image.attach(
      io: StringIO.new("\xFF\xD8\xFF\xE0" + ("x" * (16 * 1_048_576))),
      filename: "big_photo.jpg",
      content_type: "image/jpeg"
    )
    assert_not photo.valid?
    assert photo.errors[:image].any?
  end

  # TS-017-S02: GIF-Format wird abgewiesen
  test "TS-017 GIF-Format ist ungültig" do
    photo = Photo.new(gallery: @gallery)
    photo.image.attach(
      io: StringIO.new("GIF89a\x01\x00\x01\x00\x00\xff\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x00;"),
      filename: "test.gif",
      content_type: "image/gif"
    )
    assert_not photo.valid?
    assert photo.errors[:image].any?
  end
end
