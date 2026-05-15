require "test_helper"

class GalleryUploadTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "GalleryUpload-Gruppe")
    @caretaker = User.create!(email: "gallery_upload@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")

    @child_consent = Child.create!(
      first_name: "Lena", last_name: "Einwilligung",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    @child_no_consent = Child.create!(
      first_name: "Finn", last_name: "OhneEinwilligung",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: false
    )
  end

  teardown do
    Gallery.where(created_by: @caretaker).each do |g|
      g.photos.destroy_all
      g.gallery_groups.destroy_all
      g.destroy!
    end
    [ @child_consent, @child_no_consent ].each(&:destroy!)
    @caretaker.destroy!
    @group.destroy!
  end

  def fake_jpeg
    fixture_file_upload("test.jpg", "image/jpeg")
  end

  # TS-045-S01: Betreuer legt Galerie an und lädt 3 Bilder hoch
  test "TS-045 Galerie wird angelegt und 3 Bilder werden hochgeladen" do
    sign_in_as(@caretaker)

    post galleries_path, params: {
      gallery: {
        title: "Upload-Galerie",
        kindergarten_year_id: @year.id,
        group_ids: [ @group.id ],
        photos: [ fake_jpeg, fake_jpeg, fake_jpeg ]
      }
    }

    assert_response :redirect
    gallery = Gallery.find_by(title: "Upload-Galerie")
    assert gallery.present?
    assert_equal 3, gallery.photos.count
  end

  # TS-045-S02: Einwilligungs-Hinweis für Kind ohne Foto-Einwilligung
  test "TS-045 Galerie-Seite zeigt Hinweis für Kind ohne Foto-Einwilligung" do
    gallery = Gallery.new(
      title: "Einwilligungs-Test", kindergarten_year: @year, created_by: @caretaker
    )
    gallery.gallery_groups.build(group: @group)
    gallery.save!

    sign_in_as(@caretaker)
    get gallery_path(gallery)

    assert_response :success
    assert_match @child_no_consent.full_name, response.body
    assert_no_match @child_consent.full_name, response.body.gsub(/(Galerie|title|Upload)/, "")
  ensure
    gallery&.gallery_groups&.destroy_all
    gallery&.destroy!
  end
end
