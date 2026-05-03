require "test_helper"

class EncryptionTest < ActiveSupport::TestCase
  setup do
    year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Enc-Gruppe")
    @child = Child.create!(
      first_name: "Enc", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: year, photo_consent: true
    )
  end

  teardown do
    MedicalNote.where(child: @child).destroy_all
    @child.destroy!
    @group.destroy!
  end

  # TS-013-S01: MedicalNote content ist in DB verschlüsselt
  test "TS-013 medical_note content ist nicht im Klartext in der DB" do
    MedicalNote.create!(child: @child, note_type: "allergy", content: "Erdnussallergie")

    raw = ActiveRecord::Base.connection.select_value("SELECT content FROM medical_notes ORDER BY created_at DESC LIMIT 1")

    assert_not_equal "Erdnussallergie", raw
    assert raw.present?, "Verschlüsselter Wert muss vorhanden sein"
  end

  # TS-013-S02: Child insurance_number ist in DB verschlüsselt
  test "TS-013 child insurance_number ist nicht im Klartext in der DB" do
    @child.update!(insurance_number: "A123456789")

    quoted_id = ActiveRecord::Base.connection.quote(@child.id)
    raw = ActiveRecord::Base.connection.select_value(
      "SELECT insurance_number FROM children WHERE id = #{quoted_id}"
    )

    assert_not_equal "A123456789", raw
    assert raw.present?, "Verschlüsselter Wert muss vorhanden sein"
  end

  test "Sensible Parameter werden in Logs gefiltert" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    params = { email: "user@example.com", password: "secret", token: "abc123", name: "Test" }
    filtered = filter.filter(params)

    assert_equal "[FILTERED]", filtered[:email]
    assert_equal "[FILTERED]", filtered[:password]
    assert_equal "[FILTERED]", filtered[:token]
    assert_equal "Test", filtered[:name]
  end

  test "Session-Cookie ist httpOnly und SameSite=Lax konfiguriert" do
    # Prüfen, dass der Authentication-Concern die richtigen Flags setzt
    # (Integrations-Test validiert das vollständig)
    auth_concern = Authentication.instance_method(:start_new_session_for).source_location.first
    source = File.read(auth_concern)
    assert_match "httponly: true", source
    assert_match "same_site: :lax", source
    assert_match "expires: 7.days", source
  end
end
