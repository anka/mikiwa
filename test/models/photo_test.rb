require "test_helper"

class PhotoTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @group = Group.create!(name: "F73-Photo-Gruppe")
    @year  = KindergartenYear.create!(
      label: "F73-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f73_photo@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @gallery = Gallery.new(title: "F73-Galerie", kindergarten_year: @year, created_by: @caretaker)
    @gallery.gallery_groups.build(group: @group)
    @gallery.save!
  end

  def attach_image(photo, name = "sample_01.jpg")
    photo.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample_photos/#{name}")),
                       filename: name, content_type: "image/jpeg")
  end

  test "F73 Photo gehört zur Gallery und nutzt UUID-PK" do
    photo = Photo.new(gallery: @gallery)
    attach_image(photo)
    photo.save!
    assert_match(/\A[0-9a-f-]{36}\z/, photo.id)
    assert_equal @gallery, photo.gallery
  end

  test "F73 position wird automatisch hochgezählt (1, 2, 3, …)" do
    p1 = Photo.new(gallery: @gallery); attach_image(p1, "sample_01.jpg"); p1.save!
    p2 = Photo.new(gallery: @gallery); attach_image(p2, "sample_02.jpg"); p2.save!
    p3 = Photo.new(gallery: @gallery); attach_image(p3, "sample_03.jpg"); p3.save!
    assert_equal [ 1, 2, 3 ], [ p1.position, p2.position, p3.position ]
  end

  test "F73 in_order Scope sortiert nach position" do
    p1 = Photo.create!(gallery: @gallery, position: 3, image: fixture_file_upload("sample_photos/sample_01.jpg", "image/jpeg"))
    p2 = Photo.create!(gallery: @gallery, position: 1, image: fixture_file_upload("sample_photos/sample_02.jpg", "image/jpeg"))
    p3 = Photo.create!(gallery: @gallery, position: 2, image: fixture_file_upload("sample_photos/sample_03.jpg", "image/jpeg"))
    assert_equal [ p2, p3, p1 ], @gallery.photos.in_order.to_a
  end

  test "F73 Gallery#photos liefert Photos in_order via Default-Scope" do
    p1 = Photo.create!(gallery: @gallery, position: 5, image: fixture_file_upload("sample_photos/sample_01.jpg", "image/jpeg"))
    p2 = Photo.create!(gallery: @gallery, position: 1, image: fixture_file_upload("sample_photos/sample_02.jpg", "image/jpeg"))
    assert_equal [ p2, p1 ], @gallery.photos.to_a
  end

  test "F73 caption darf höchstens 200 Zeichen haben" do
    photo = Photo.new(gallery: @gallery, caption: "x" * 201)
    attach_image(photo)
    assert_not photo.valid?
    assert photo.errors[:caption].any?
  end

  test "F73 Photo ohne attached image ist invalid" do
    photo = Photo.new(gallery: @gallery)
    assert_not photo.valid?
    assert photo.errors[:image].any?
  end

  test "F73 Gallery#destroy löscht zugehörige Photos" do
    Photo.create!(gallery: @gallery, image: fixture_file_upload("sample_photos/sample_01.jpg", "image/jpeg"))
    assert_difference "Photo.count", -1 do
      @gallery.destroy
    end
  end
end
