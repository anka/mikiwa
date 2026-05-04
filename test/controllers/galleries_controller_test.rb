require "test_helper"

class GalleriesControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @caretaker = User.create!(email: "betreuer_galc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_galc@mikiwa.at",   password: SecureRandom.hex(20), role: "parent")
    @parent2   = User.create!(email: "eltern2_galc@mikiwa.at",  password: SecureRandom.hex(20), role: "parent")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Galerie-Bären2")
    @group_loewen = Group.create!(name: "Galerie-Löwen2")

    @child = Child.create!(
      first_name: "Mia", last_name: "Fischer",
      date_of_birth: Date.new(2021, 4, 1),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    @child_no_consent = Child.create!(
      first_name: "Kai", last_name: "Wolf",
      date_of_birth: Date.new(2021, 6, 1),
      group: @group_baeren, kindergarten_year: @year, photo_consent: false
    )
    ParentChild.create!(user: @parent, child: @child)

    @gallery = Gallery.new(
      title: "Sommerfest",
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @gallery.gallery_groups.build(group: @group_baeren)
    @gallery.save!

    @gallery_loewen = Gallery.new(
      title: "Löwen-Ausflug",
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @gallery_loewen.gallery_groups.build(group: @group_loewen)
    @gallery_loewen.save!
  end

  # --- Auth guard ---
  test "unauthenticated user is redirected" do
    get galleries_path
    assert_redirected_to new_session_path
  end

  # --- Index ---
  test "caretaker sees all galleries" do
    sign_in_as(@caretaker)
    get galleries_path
    assert_response :success
    assert_match "Sommerfest", response.body
    assert_match "Löwen-Ausflug", response.body
  end

  test "parent sees only galleries for own group" do
    sign_in_as(@parent)
    get galleries_path
    assert_response :success
    assert_match "Sommerfest", response.body
    assert_no_match "Löwen-Ausflug", response.body
  end

  # --- Show ---
  test "authenticated user can view gallery" do
    sign_in_as(@parent)
    get gallery_path(@gallery)
    assert_response :success
    assert_match "Sommerfest", response.body
  end

  test "parent from other group cannot view gallery (403)" do
    sign_in_as(@parent2)
    get gallery_path(@gallery)
    assert_response :forbidden
  end

  # --- Create ---
  test "caretaker can create gallery" do
    sign_in_as(@caretaker)
    assert_difference "Gallery.count", 1 do
      post galleries_path, params: {
        gallery: {
          title: "Neue Galerie",
          kindergarten_year_id: @year.id,
          group_ids: [ @group_baeren.id ]
        }
      }
    end
    assert_redirected_to gallery_path(Gallery.order(:created_at).last)
  end

  # BF-003: Galleries Validierungsfehler obwohl Gruppen ausgewählt
  test "BF-003 caretaker can update gallery groups" do
    sign_in_as(@caretaker)
    patch gallery_path(@gallery), params: {
      gallery: {
        title:                @gallery.title,
        kindergarten_year_id: @year.id,
        group_ids:            [ @group_loewen.id ]
      }
    }
    assert_redirected_to gallery_path(@gallery)
    assert_equal [ @group_loewen.id ], @gallery.reload.groups.pluck(:id)
  end

  test "BF-003 create with empty group_ids zeigt Validierungsfehler (kein Bug)" do
    sign_in_as(@caretaker)
    assert_no_difference "Gallery.count" do
      post galleries_path, params: {
        gallery: {
          title: "Ohne Gruppe",
          kindergarten_year_id: @year.id,
          group_ids: []
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/mindestens eine Gruppe/i, response.body)
  end

  test "BF-003 update mit gleicher Gruppe wirft keinen Validierungsfehler" do
    sign_in_as(@caretaker)
    patch gallery_path(@gallery), params: {
      gallery: {
        title:                @gallery.title,
        kindergarten_year_id: @year.id,
        group_ids:            [ @group_baeren.id ]
      }
    }
    assert_redirected_to gallery_path(@gallery)
  end

  test "BF-003 update mit Validierungsfehler verliert KEINE bestehenden Gruppen (Datenintegrität)" do
    sign_in_as(@caretaker)
    original_group_ids = @gallery.groups.pluck(:id)
    assert_not_empty original_group_ids

    patch gallery_path(@gallery), params: {
      gallery: {
        title: "",  # Pflichtfeld leer → Validierung schlägt fehl
        kindergarten_year_id: @year.id,
        group_ids: [ @group_loewen.id ]
      }
    }
    assert_response :unprocessable_entity
    assert_equal original_group_ids.sort, @gallery.reload.groups.pluck(:id).sort
  end

  test "BF-003 update mit mehreren Gruppen funktioniert" do
    sign_in_as(@caretaker)
    patch gallery_path(@gallery), params: {
      gallery: {
        title:                @gallery.title,
        kindergarten_year_id: @year.id,
        group_ids:            [ @group_baeren.id, @group_loewen.id ]
      }
    }
    assert_redirected_to gallery_path(@gallery)
    assert_equal [ @group_baeren.id, @group_loewen.id ].sort,
                 @gallery.reload.groups.pluck(:id).sort
  end

  test "parent cannot create gallery (403)" do
    sign_in_as(@parent)
    post galleries_path, params: {
      gallery: { title: "X", kindergarten_year_id: @year.id, group_ids: [ @group_baeren.id ] }
    }
    assert_response :forbidden
  end

  # --- Einwilligungs-Hinweis in Show ---
  test "show displays consent warning for children without consent" do
    sign_in_as(@caretaker)
    get gallery_path(@gallery)
    assert_response :success
    assert_match @child_no_consent.full_name, response.body
  end

  # --- Remove photo ---
  test "parent cannot remove photo (403)" do
    sign_in_as(@parent)
    delete remove_photo_gallery_path(@gallery, photo_id: "fakeid")
    assert_response :forbidden
  end

  test "caretaker gets 404 removing non-existent photo" do
    sign_in_as(@caretaker)
    delete remove_photo_gallery_path(@gallery, photo_id: "99999999")
    assert_response :not_found
  end

  # --- Download ---
  test "parent from other group cannot download photo (403)" do
    sign_in_as(@parent2)
    get download_gallery_path(@gallery, photo_id: "fakeid")
    assert_response :forbidden
  end

  test "parent in group gets 404 downloading non-existent photo" do
    sign_in_as(@parent)
    get download_gallery_path(@gallery, photo_id: "99999999")
    assert_response :not_found
  end

  private

  def minimal_jpeg
    # Include unique bytes so parallel tests don't share the same blob key
    "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00" +
      SecureRandom.hex(8) +
      "\xFF\xD9"
  end
end
