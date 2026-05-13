require "test_helper"

class GalleryParentTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group_bears = Group.create!(name: "GParent-Bären")
    @group_lions = Group.create!(name: "GParent-Löwen")
    @caretaker = User.create!(email: "gparent_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "gparent_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child = Child.create!(
      first_name: "GPKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group_bears, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @gallery_bears = Gallery.new(
      title: "Bären-Galerie", kindergarten_year: @year, created_by: @caretaker
    )
    @gallery_bears.gallery_groups.build(group: @group_bears)
    @gallery_bears.save!

    @gallery_lions = Gallery.new(
      title: "Löwen-Galerie", kindergarten_year: @year, created_by: @caretaker
    )
    @gallery_lions.gallery_groups.build(group: @group_lions)
    @gallery_lions.save!
  end

  teardown do
    [ @gallery_bears, @gallery_lions ].each do |g|
      g.photos.purge rescue nil
      g.gallery_groups.destroy_all
      g.destroy!
    end
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group_bears.destroy!
    @group_lions.destroy!
  end

  # TS-046-S01: Elternteil sieht nur Galerien eigener Gruppe
  test "TS-046 Elternteil sieht keine Galerie fremder Gruppen" do
    sign_in_as(@parent)
    get galleries_path

    assert_response :success
    assert_match "Bären-Galerie",   response.body
    assert_no_match "Löwen-Galerie", response.body
  end

  # TS-046-S02: Elternteil ohne Zugehörigkeit erhält 403 beim Download
  test "TS-046 Download einer Galerie fremder Gruppe ist nicht erlaubt" do
    sign_in_as(@parent)

    get download_gallery_path(@gallery_lions, photo_id: SecureRandom.uuid)
    assert_response :forbidden
  end
end
