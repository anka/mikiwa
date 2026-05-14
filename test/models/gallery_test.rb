require "test_helper"

class GalleryTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @group_a  = Group.create!(name: "Galerie-Bären")
    @group_b  = Group.create!(name: "Galerie-Löwen")
    @year     = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "betreuer_gal@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")

    @child_consent    = Child.create!(
      first_name: "Lukas", last_name: "Maier",
      date_of_birth: Date.new(2021, 3, 1),
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_no_consent = Child.create!(
      first_name: "Anna", last_name: "Huber",
      date_of_birth: Date.new(2021, 7, 1),
      group: @group_a, kindergarten_year: @year, photo_consent: false
    )

    @gallery = Gallery.new(
      title: "Waldtag Mai",
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @gallery.gallery_groups.build(group: @group_a)
  end

  test "valid gallery can be saved" do
    assert @gallery.save, @gallery.errors.full_messages.inspect
  end

  test "uses UUID primary key" do
    @gallery.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @gallery.id)
  end

  test "title is required" do
    @gallery.title = nil
    assert_not @gallery.valid?
    assert @gallery.errors[:title].any?
  end

  test "at least one group required" do
    gallery = Gallery.new(title: "Leer", kindergarten_year: @year, created_by: @caretaker)
    assert_not gallery.valid?
    assert gallery.errors[:gallery_groups].any?
  end

  test "consent_warnings returns children without photo_consent in group" do
    @gallery.save!
    warnings = @gallery.consent_warnings(@group_a)
    assert_includes warnings, @child_no_consent
    assert_not_includes warnings, @child_consent
  end

  test "consent_warnings returns empty when all children have consent" do
    @group_b_child = Child.create!(
      first_name: "Tom", last_name: "Bauer",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group_b, kindergarten_year: @year, photo_consent: true
    )
    @gallery.gallery_groups.build(group: @group_b)
    @gallery.save!
    warnings = @gallery.consent_warnings(@group_b)
    assert_empty warnings
  end

  test "photos count for gallery returns zero when no photos" do
    @gallery.save!
    assert_equal 0, @gallery.photos.count
  end

  # F37 – visibility enum
  test "F37 neue Galerie hat visibility internal als Default" do
    @gallery.save!
    assert @gallery.internal?
    assert_not @gallery.released?
  end

  test "F37 Galerie kann auf released gesetzt werden" do
    @gallery.save!
    @gallery.update!(visibility: :released)
    assert @gallery.released?
  end

  test "F37 visibility-Enum hat die Werte internal und released" do
    assert_equal({ "internal" => 0, "released" => 1 }, Gallery.visibilities)
  end

  # F57 – Slideshow-Geschwindigkeit pro Galerie
  test "F57 neue Galerie hat slideshow_speed normal als Default" do
    @gallery.save!
    assert_equal "normal", @gallery.reload.slideshow_speed
    assert @gallery.slideshow_speed_normal?
  end

  test "F57 slideshow_speed kann auf slow oder fast gesetzt werden" do
    @gallery.save!
    @gallery.update!(slideshow_speed: :slow)
    assert @gallery.slideshow_speed_slow?
    @gallery.update!(slideshow_speed: :fast)
    assert @gallery.slideshow_speed_fast?
  end

  test "F57 slideshow_speed-Enum hat die Werte slow, normal, fast" do
    assert_equal(
      { "slow" => "slow", "normal" => "normal", "fast" => "fast" },
      Gallery.slideshow_speeds
    )
  end

  test "F57 ungültiger slideshow_speed wird abgelehnt" do
    @gallery.save!
    assert_raises(ArgumentError) { @gallery.slideshow_speed = "ultra" }
  end

  # F58 – Audio-Upload-Validierung
  test "F58 Galerie ohne Audio bleibt valide" do
    @gallery.save!
    assert_not @gallery.audio.attached?
    assert @gallery.valid?
  end

  test "F58 MP3-Audio mit gültigem Content-Type wird akzeptiert" do
    @gallery.save!
    @gallery.audio.attach(
      io: StringIO.new("\xFF\xFBfake-mp3-data"),
      filename: "song.mp3",
      content_type: "audio/mpeg"
    )
    assert @gallery.valid?, @gallery.errors.full_messages.inspect
  end

  test "F58 M4A-Audio mit gültigem Content-Type wird akzeptiert" do
    @gallery.save!
    @gallery.audio.attach(
      io: StringIO.new("fake-m4a-data"),
      filename: "song.m4a",
      content_type: "audio/mp4"
    )
    assert @gallery.valid?, @gallery.errors.full_messages.inspect
  end

  test "F58 audio/x-m4a Content-Type wird akzeptiert" do
    @gallery.save!
    @gallery.audio.attach(
      io: StringIO.new("fake-m4a-data"),
      filename: "song.m4a",
      content_type: "audio/x-m4a"
    )
    assert @gallery.valid?
  end

  test "F58 ungültiger Audio-Content-Type wird abgelehnt" do
    @gallery.save!
    @gallery.audio.attach(
      io: StringIO.new("fake-wav-data"),
      filename: "song.wav",
      content_type: "audio/wav"
    )
    assert_not @gallery.valid?
    assert_includes @gallery.errors[:audio].first, "MP3"
  end

  test "F58 Audio über 25 MB wird abgelehnt" do
    @gallery.save!
    big = "x" * (25 * 1024 * 1024 + 1)
    @gallery.audio.attach(
      io: StringIO.new(big),
      filename: "huge.mp3",
      content_type: "audio/mpeg"
    )
    assert_not @gallery.valid?
    assert_includes @gallery.errors[:audio].first, "25"
  end
end
