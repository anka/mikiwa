require "test_helper"

class GalleriesControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @caretaker = User.create!(email: "betreuer_galc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_galc@mikiwa.at",   password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @parent2   = User.create!(email: "eltern2_galc@mikiwa.at",  password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 001")
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

  test "parent sees only released galleries for own group" do
    @gallery.update!(visibility: :released)
    sign_in_as(@parent)
    get galleries_path
    assert_response :success
    assert_match "Sommerfest", response.body
    assert_no_match "Löwen-Ausflug", response.body
  end

  # --- Show ---
  test "authenticated user can view released gallery" do
    @gallery.update!(visibility: :released)
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

  # F29: Mehrfach-Upload mit Drag & Drop
  test "F29 add_photo akzeptiert gültiges Bild und attached es" do
    sign_in_as(@caretaker)
    photo = fixture_file_upload(Rails.root.join("test/fixtures/files/sample_photo.jpg"), "image/jpeg")

    assert_difference "@gallery.photos.attachments.count", 1 do
      post add_photo_gallery_path(@gallery), params: { photo: photo }
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert body["ok"]
  end

  test "F29 add_photo lehnt ungültiges Format ab (422)" do
    sign_in_as(@caretaker)
    bogus = fixture_file_upload(Rails.root.join("test/fixtures/files/sample.txt"), "text/plain")

    assert_no_difference "@gallery.photos.attachments.count" do
      post add_photo_gallery_path(@gallery), params: { photo: bogus }
    end
    assert_response :unprocessable_entity
    assert_match(/Format nicht erlaubt/i, response.body)
  end

  test "F29 add_photo verweigert Eltern (403)" do
    sign_in_as(@parent)
    photo = fixture_file_upload(Rails.root.join("test/fixtures/files/sample_photo.jpg"), "image/jpeg")
    post add_photo_gallery_path(@gallery), params: { photo: photo }
    assert_response :forbidden
  end

  test "F29 add_photo ohne Datei → 422" do
    sign_in_as(@caretaker)
    post add_photo_gallery_path(@gallery)
    assert_response :unprocessable_entity
    assert_match(/Keine Datei/i, response.body)
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

  test "parent in group gets 404 downloading non-existent photo from released gallery" do
    @gallery.update!(visibility: :released)
    sign_in_as(@parent)
    get download_gallery_path(@gallery, photo_id: "99999999")
    assert_response :not_found
  end

  # F37 – visibility / Freigabe
  test "F37 parent sieht nur freigegebene Galerien im Index" do
    @gallery.update!(visibility: :internal)
    sign_in_as(@parent)
    get galleries_path
    assert_response :success
    assert_no_match "Sommerfest", response.body
  end

  test "F37 parent sieht freigegebene Galerie im Index" do
    @gallery.update!(visibility: :released)
    sign_in_as(@parent)
    get galleries_path
    assert_response :success
    assert_match "Sommerfest", response.body
  end

  test "F37 parent bekommt 403 beim Aufruf einer internen Galerie" do
    @gallery.update!(visibility: :internal)
    sign_in_as(@parent)
    get gallery_path(@gallery)
    assert_response :forbidden
  end

  test "F37 Betreuer sieht interne und freigegebene Galerien im Index" do
    @gallery.update!(visibility: :internal)
    sign_in_as(@caretaker)
    get galleries_path
    assert_response :success
    assert_match "Sommerfest", response.body
  end

  test "F37 Betreuer kann Galerie freigeben" do
    @gallery.update!(visibility: :internal)
    sign_in_as(@caretaker)
    patch release_gallery_path(@gallery)
    assert_redirected_to gallery_path(@gallery)
    assert @gallery.reload.released?
  end

  test "F37 Betreuer kann freigegebene Galerie zurückziehen" do
    @gallery.update!(visibility: :released)
    sign_in_as(@caretaker)
    patch withdraw_gallery_path(@gallery)
    assert_redirected_to gallery_path(@gallery)
    assert @gallery.reload.internal?
  end

  test "F37 parent kann Galerie nicht freigeben (403)" do
    @gallery.update!(visibility: :internal)
    sign_in_as(@parent)
    patch release_gallery_path(@gallery)
    assert_response :forbidden
  end

  test "F37 Galerie mit sofort_freigeben=true wird released erstellt" do
    sign_in_as(@caretaker)
    post galleries_path, params: {
      gallery: {
        title: "Sofort-Galerie",
        kindergarten_year_id: @year.id,
        group_ids: [ @group_baeren.id ],
        visibility: "released"
      }
    }
    created = Gallery.order(:created_at).last
    assert created.released?
  end

  # F53: Magic Slideshow
  test "F53 Show zeigt 'Magic Slideshow'-Action" do
    sign_in_as(@caretaker)
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "f53.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    assert_match(/Magic Slideshow/, response.body)
    assert_select 'button[title="Magic Slideshow"][data-action*="magic-slideshow#open"]'
  end

  test "F53 Show ohne Fotos zeigt keine 'Magic Slideshow'-Action" do
    sign_in_as(@caretaker)
    get gallery_path(@gallery)
    assert_response :success
    assert_no_match(/Magic Slideshow/, response.body)
  end

  # F52: Lightbox nur über Action öffnen
  test "F52 Show zeigt 'Galerie ansehen'-Action mit data-action zum Öffnen" do
    sign_in_as(@caretaker)
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "f52.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    assert_match(/Galerie ansehen/, response.body)
    assert_select 'button[title="Galerie ansehen"][data-action*="lightbox#open"][data-lightbox-index-param="0"]'
  end

  test "F52 Show ohne Fotos zeigt keine 'Galerie ansehen'-Action" do
    sign_in_as(@caretaker)
    get gallery_path(@gallery)
    assert_response :success
    assert_no_match(/Galerie ansehen/, response.body)
  end

  # F57: Slideshow-Geschwindigkeit als Galerie-Einstellung
  test "F57 Form enthält slideshow_speed-Select mit drei Optionen" do
    sign_in_as(@caretaker)
    get edit_gallery_path(@gallery)
    assert_response :success
    assert_select 'select[name="gallery[slideshow_speed]"]' do
      assert_select 'option[value="slow"]'
      assert_select 'option[value="normal"]'
      assert_select 'option[value="fast"]'
    end
  end

  test "F57 caretaker kann slideshow_speed beim Update setzen" do
    sign_in_as(@caretaker)
    patch gallery_path(@gallery), params: {
      gallery: {
        title:                @gallery.title,
        kindergarten_year_id: @year.id,
        group_ids:            [ @group_baeren.id ],
        slideshow_speed:      "fast"
      }
    }
    assert_redirected_to gallery_path(@gallery)
    assert_equal "fast", @gallery.reload.slideshow_speed
  end

  test "F57 Show gibt slideshow_speed als data-Attribute am Magic-Slideshow-Container aus" do
    sign_in_as(@caretaker)
    @gallery.update!(slideshow_speed: :fast)
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "f57.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    assert_select 'div[data-controller~="magic-slideshow"][data-magic-slideshow-speed-value="fast"]'
  end

  test "F57 Show ohne expliziten Speed nutzt 'normal' im data-Attribute" do
    sign_in_as(@caretaker)
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "f57b.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    assert_select 'div[data-controller~="magic-slideshow"][data-magic-slideshow-speed-value="normal"]'
  end

  # F58: Audio-Upload & Slideshow-Begleitmusik
  test "F58 Edit-Form enthält Audio-Upload-Feld" do
    sign_in_as(@caretaker)
    get edit_gallery_path(@gallery)
    assert_response :success
    assert_select 'input[type="file"][name="gallery[audio]"][accept*="audio/mpeg"]'
  end

  test "F58 caretaker kann MP3 hochladen" do
    sign_in_as(@caretaker)
    mp3 = fixture_file_upload(Rails.root.join("test/fixtures/files/sample_audio.mp3"), "audio/mpeg")
    patch gallery_path(@gallery), params: {
      gallery: {
        title:                @gallery.title,
        kindergarten_year_id: @year.id,
        group_ids:            [ @group_baeren.id ],
        audio:                mp3
      }
    }
    assert_redirected_to gallery_path(@gallery)
    assert @gallery.reload.audio.attached?
  end

  test "F58 ungültiger Audio-Typ wird abgelehnt (422)" do
    sign_in_as(@caretaker)
    wav = fixture_file_upload(Rails.root.join("test/fixtures/files/sample.txt"), "audio/wav")
    patch gallery_path(@gallery), params: {
      gallery: {
        title:                @gallery.title,
        kindergarten_year_id: @year.id,
        group_ids:            [ @group_baeren.id ],
        audio:                wav
      }
    }
    assert_response :unprocessable_entity
    assert_not @gallery.reload.audio.attached?
  end

  test "F58 Show enthält audio-Element wenn Audio attached" do
    sign_in_as(@caretaker)
    @gallery.audio.attach(
      io: StringIO.new("\xFF\xFBfake-mp3"),
      filename: "song.mp3",
      content_type: "audio/mpeg"
    )
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "f58.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    assert_select 'audio[data-magic-slideshow-target="audio"]'
  end

  test "F58 Show ohne Audio enthält kein audio-Element" do
    sign_in_as(@caretaker)
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "f58b.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    assert_select 'audio[data-magic-slideshow-target="audio"]', count: 0
  end

  test "F58 Edit-Form: Entfernen-Button steckt NICHT im Edit-form (kein nested form)" do
    sign_in_as(@caretaker)
    @gallery.audio.attach(
      io: StringIO.new("\xFF\xFBfake-mp3"),
      filename: "song.mp3",
      content_type: "audio/mpeg"
    )
    @gallery.save!
    get edit_gallery_path(@gallery)
    assert_response :success
    # Der Lösch-Mechanismus darf nicht als <form>/<button> innerhalb des
    # Outer-Edit-Forms gerendert werden – sonst submittet der Klick den
    # Outer-PATCH (Browser entfernt nested <form>). Statt button_to nutzen
    # wir link_to mit data-turbo-method="delete".
    assert_select 'a[href*="/audio"][data-turbo-method="delete"]'
    assert_select 'form#gallery_form form', count: 0
  end

  test "F58 caretaker kann Audio via purge_audio entfernen" do
    sign_in_as(@caretaker)
    @gallery.audio.attach(
      io: StringIO.new("\xFF\xFBfake-mp3"),
      filename: "song.mp3",
      content_type: "audio/mpeg"
    )
    @gallery.save!
    assert @gallery.reload.audio.attached?
    delete purge_audio_gallery_path(@gallery)
    assert_redirected_to edit_gallery_path(@gallery)
    assert_not @gallery.reload.audio.attached?
  end

  test "F58 parent kann Audio nicht entfernen (403)" do
    sign_in_as(@parent)
    delete purge_audio_gallery_path(@gallery)
    assert_response :forbidden
  end

  # BF-006: CSP-Fehler auf Gallery-Detail
  test "BF-006 Show enthält keine inline style='display:none' Attribute (CSP)" do
    sign_in_as(@caretaker)
    @gallery.photos.attach(io: StringIO.new(minimal_jpeg), filename: "csp.jpg", content_type: "image/jpeg")
    @gallery.save!
    get gallery_path(@gallery)
    assert_response :success
    # data-lightbox-src spans dürfen kein inline style="display:..." haben
    refute_match(/<span[^>]+data-lightbox-src=[^>]+style="display:\s*none"/, response.body,
                 "Lightbox-src-Span muss CSS-Klasse statt inline style nutzen (CSP)")
  end

  private

  def minimal_jpeg
    # Include unique bytes so parallel tests don't share the same blob key
    "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00" +
      SecureRandom.hex(8) +
      "\xFF\xD9"
  end
end
