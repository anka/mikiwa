require "test_helper"

class AdditionalCoverageTest < ActiveSupport::TestCase
  # Gruppe model
  test "Gruppe mit optionaler Farbe und Beschreibung" do
    g = Gruppe.create!(name: "Schmetterlinge", farbe: "#FF6B6B", beschreibung: "Unsere kleinste Gruppe")
    assert_equal "#FF6B6B", g.farbe
    assert_equal "Unsere kleinste Gruppe", g.beschreibung
  end

  # Kindergartenjahr model
  test "Kindergartenjahr ohne aktiv=true ist nicht aktiv" do
    kgj = Kindergartenjahr.create!(
      bezeichnung: "KGJ 2024/25",
      start_datum: Date.new(2024, 9, 1),
      end_datum: Date.new(2025, 7, 31),
      aktiv: false
    )
    assert_not kgj.aktiv?
  end

  # User model role helpers
  test "User admin? caretaker? parent? Hilfsmethoden" do
    admin = User.create!(email: "a@t.com", password: "sicherespasswort1234", role: "admin")
    caretaker = User.create!(email: "b@t.com", password: "sicherespasswort1234", role: "caretaker")
    parent = User.create!(email: "c@t.com", password: SecureRandom.hex(20), role: "parent")

    assert admin.admin?
    assert_not admin.caretaker?
    assert admin.staff?

    assert caretaker.caretaker?
    assert caretaker.staff?
    assert_not caretaker.parent?

    assert parent.parent?
    assert_not parent.staff?
    assert_not parent.admin?
  end

  # User email_invalid flag
  test "User email_invalid Standardwert ist false" do
    user = User.create!(email: "new@test.com", password: "sicherespasswort1234")
    assert_not user.email_invalid?
  end

  # ApplicationPolicy Scope
  test "ApplicationPolicy::Scope wirft NotImplementedError" do
    user = User.create!(email: "scope@test.com", password: "sicherespasswort1234")
    scope = ApplicationPolicy::Scope.new(user, User)
    assert_raises(NotImplementedError) { scope.resolve }
  end

  # MagicLink Mailer
  test "MagicLinkMailer login hat beide Varianten" do
    parent = User.create!(email: "ml@test.com", password: SecureRandom.hex(20), role: "parent")
    mail = MagicLinkMailer.login(parent)
    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html"
    assert_includes content_types, "text/plain"
    assert_equal [ parent.email ], mail.to
  end

  # User invalidate_magic_link_token!
  test "invalidate_magic_link_token! erhöht Version" do
    user = User.create!(email: "inv@test.com", password: SecureRandom.hex(20), role: "parent")
    original_version = user.magic_link_token_version
    user.invalidate_magic_link_token!
    assert_equal original_version + 1, user.reload.magic_link_token_version
  end

  # ImageAttachable VARIANT_CONFIGS
  test "ImageAttachable hat alle drei Varianten konfiguriert" do
    assert ImageAttachable::VARIANT_CONFIGS.key?(:thumb)
    assert ImageAttachable::VARIANT_CONFIGS.key?(:display)
    assert ImageAttachable::VARIANT_CONFIGS.key?(:original)
    assert_equal :webp, ImageAttachable::VARIANT_CONFIGS[:thumb][:format]
    assert_equal :webp, ImageAttachable::VARIANT_CONFIGS[:display][:format]
  end
end
