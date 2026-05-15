require "test_helper"

class GalleriesMultiUploadTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  SAMPLE_DIR = Rails.root.join("test/fixtures/files/sample_photos")

  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "BF009-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "BF009-Gruppe")
    @caretaker = User.create!(email: "bf009_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @gallery = Gallery.new(title: "BF009-Galerie", kindergarten_year: @year, created_by: @caretaker)
    @gallery.gallery_groups.build(group: @group)
    @gallery.save!
  end

  teardown do
    @gallery.photos.destroy_all
    @gallery.gallery_groups.destroy_all
    @gallery.destroy
    @caretaker.destroy
    @group.destroy
  end

  test "BF-009 Sample-JPGs sind als Fixtures vorhanden" do
    assert Dir.exist?(SAMPLE_DIR), "sample_photos directory fehlt"
    files = Dir.glob(SAMPLE_DIR.join("sample_*.jpg")).sort
    assert_equal 10, files.size, "Es sollten genau 10 sample_*.jpg vorhanden sein"
    files.each do |f|
      assert File.size(f) > 0, "#{f} hat 0 Bytes"
    end
  end

  test "BF-009 Multi-Upload: 10 Fotos sequenziell via add_photo persistieren alle" do
    sign_in_as(@caretaker)

    files = (1..10).map do |i|
      fixture_file_upload("sample_photos/sample_#{i.to_s.rjust(2, '0')}.jpg", "image/jpeg")
    end

    files.each do |file|
      post add_photo_gallery_path(@gallery), params: { photo: file }, headers: { "Accept" => "application/json" }
      assert_response :success, "Upload für #{file.original_filename} fehlgeschlagen: #{response.body}"
    end

    @gallery.reload
    assert_equal 10, @gallery.photos.count, "Erwartet: 10 Photos, gefunden: #{@gallery.photos.count}"
  end

  test "BF-009 Multi-Upload: 1 invalides + 9 valide → 9 Photos persistieren, 1 Fehler" do
    sign_in_as(@caretaker)

    valid_files = (1..9).map do |i|
      fixture_file_upload("sample_photos/sample_#{i.to_s.rjust(2, '0')}.jpg", "image/jpeg")
    end
    invalid_file = fixture_file_upload("sample.txt", "text/plain")

    valid_files.each do |file|
      post add_photo_gallery_path(@gallery), params: { photo: file }, headers: { "Accept" => "application/json" }
      assert_response :success
    end
    post add_photo_gallery_path(@gallery), params: { photo: invalid_file }, as: :json
    assert_response :unprocessable_entity

    @gallery.reload
    assert_equal 9, @gallery.photos.count
  end

  test "BF-009 Concurrency: 10 parallele Photo.create!-Calls persistieren alle 10" do
    files = (1..10).map do |i|
      Rails.root.join("test/fixtures/files/sample_photos/sample_#{i.to_s.rjust(2, '0')}.jpg")
    end

    # Echte Concurrency simulieren via Threads. Mit dem neuen Photo-Modell
    # (F73) ist jeder Insert ein eigener INSERT INTO photos – keine
    # geteilte Memory-Collection mehr. So fallen alle 10 Requests durch.
    threads = files.map do |path|
      Thread.new do
        record = Photo.new(gallery: Gallery.find(@gallery.id))
        record.image.attach(io: File.open(path), filename: File.basename(path), content_type: "image/jpeg")
        record.save!
      end
    end
    threads.each(&:join)

    @gallery.reload
    assert_equal 10, @gallery.photos.count, "Erwartet: 10 Photos parallel, gefunden: #{@gallery.photos.count}"
  end

  test "BF-009 Stress: 20 Fotos sequenziell → mind. 19 erfolgreich" do
    sign_in_as(@caretaker)

    # 20 Files: 10 unique + 10 wiederholungen
    files = (1..20).map do |i|
      idx = ((i - 1) % 10) + 1
      fixture_file_upload("sample_photos/sample_#{idx.to_s.rjust(2, '0')}.jpg", "image/jpeg")
    end

    successes = 0
    files.each do |file|
      post add_photo_gallery_path(@gallery), params: { photo: file }, headers: { "Accept" => "application/json" }
      successes += 1 if response.successful?
    end

    @gallery.reload
    assert successes >= 19, "Erwartet mind. 19 erfolgreiche Uploads, gefunden: #{successes}"
    assert @gallery.photos.count >= 19, "Erwartet mind. 19 Photos in DB, gefunden: #{@gallery.photos.count}"
  end
end
