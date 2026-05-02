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
end
