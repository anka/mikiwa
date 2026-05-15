require "test_helper"

class PhotosControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @group = Group.create!(name: "F73-Ctrl-Gruppe")
    @year  = KindergartenYear.create!(
      label: "F73-Ctrl-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "f73_ctrl@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "f73_ctrl_parent@mikiwa.at", password: SecureRandom.hex(20),
                               role: "parent", first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @gallery = Gallery.new(title: "F73-Galerie", kindergarten_year: @year, created_by: @caretaker)
    @gallery.gallery_groups.build(group: @group)
    @gallery.save!

    @p1 = Photo.create!(gallery: @gallery, image: fixture_file_upload("sample_photos/sample_01.jpg", "image/jpeg"))
    @p2 = Photo.create!(gallery: @gallery, image: fixture_file_upload("sample_photos/sample_02.jpg", "image/jpeg"))
    @p3 = Photo.create!(gallery: @gallery, image: fixture_file_upload("sample_photos/sample_03.jpg", "image/jpeg"))
  end

  test "F73 reorder als Staff setzt position laut photo_ids" do
    sign_in_as(@caretaker)
    patch reorder_gallery_photos_path(@gallery), params: { photo_ids: [ @p3.id, @p1.id, @p2.id ] }
    assert_response :success
    assert_equal 1, @p3.reload.position
    assert_equal 2, @p1.reload.position
    assert_equal 3, @p2.reload.position
    assert_equal [ @p3, @p1, @p2 ], @gallery.photos.in_order.to_a
  end

  test "F73 reorder mit unvollständigen photo_ids → 422 + keine Änderung" do
    sign_in_as(@caretaker)
    original = [ @p1.position, @p2.position, @p3.position ]
    patch reorder_gallery_photos_path(@gallery), params: { photo_ids: [ @p1.id, @p2.id ] }
    assert_response :unprocessable_entity
    assert_equal original, [ @p1.reload.position, @p2.reload.position, @p3.reload.position ]
  end

  test "F73 reorder als Parent → 403" do
    sign_in_as(@parent)
    patch reorder_gallery_photos_path(@gallery), params: { photo_ids: [ @p3.id, @p1.id, @p2.id ] }
    assert_response :forbidden
  end

  test "F73 destroy als Staff entfernt Photo" do
    sign_in_as(@caretaker)
    assert_difference "Photo.count", -1 do
      delete gallery_photo_path(@gallery, @p1)
    end
    assert_redirected_to gallery_path(@gallery)
  end

  test "F73 destroy als Parent → 403" do
    sign_in_as(@parent)
    assert_no_difference "Photo.count" do
      delete gallery_photo_path(@gallery, @p1)
    end
    assert_response :forbidden
  end

  test "F74 update als Staff mit valider Caption speichert caption" do
    sign_in_as(@caretaker)
    patch gallery_photo_path(@gallery, @p1),
          params: { photo: { caption: "Beim Sommerfest" } }
    assert_response :success
    assert_equal "Beim Sommerfest", @p1.reload.caption
  end

  test "F74 update als Staff: Caption darf geleert werden" do
    @p1.update!(caption: "Alt")
    sign_in_as(@caretaker)
    patch gallery_photo_path(@gallery, @p1),
          params: { photo: { caption: "" } }
    assert_response :success
    assert_nil @p1.reload.caption.presence
  end

  test "F74 update mit Caption > 200 Zeichen → 422" do
    sign_in_as(@caretaker)
    patch gallery_photo_path(@gallery, @p1),
          params: { photo: { caption: "x" * 201 } }
    assert_response :unprocessable_entity
    assert_nil @p1.reload.caption
  end

  test "F74 update als Parent → 403" do
    sign_in_as(@parent)
    patch gallery_photo_path(@gallery, @p1),
          params: { photo: { caption: "Hack" } }
    assert_response :forbidden
    assert_nil @p1.reload.caption
  end
end
