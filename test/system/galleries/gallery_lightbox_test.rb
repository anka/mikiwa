require "test_helper"

class GalleryLightboxTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Lightbox-Gruppe")
    @caretaker = User.create!(
      email: "lightbox_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @parent = User.create!(
      email: "lightbox_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000"
    )
    @child = Child.create!(
      first_name: "LightboxKind", last_name: "Test",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @gallery = Gallery.new(
      title: "Lightbox-Galerie", kindergarten_year: @year, created_by: @caretaker
    )
    @gallery.gallery_groups.build(group: @group)
    @gallery.save!
    Photo.create!(gallery: @gallery, image: fixture_file_upload("test.jpg", "image/jpeg"))
  end

  teardown do
    @gallery.photos.destroy_all
    @gallery.gallery_groups.destroy_all
    @gallery.destroy!
    ParentChild.where(user: @parent, child: @child).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-068-S01: Lightbox-Dialog und Datenattribute für Foto-Klick vorhanden
  test "TS-068 Galerie-Seite enthält Lightbox-Dialog und Auslöser-Attribute" do
    sign_in_as(@parent)
    get gallery_path(@gallery)

    assert_response :success
    assert_match "mw-lightbox", response.body, "Lightbox-Dialog muss im HTML vorhanden sein"
    assert_match "lightbox#open", response.body, "Foto-Buttons müssen Lightbox-Open-Action haben"
    assert_match "lightbox#close", response.body, "Schließen-Button muss Lightbox-Close-Action haben"
    assert_match "data-lightbox-src", response.body, "Bild-URLs müssen als data-lightbox-src vorliegen"
  end
end
