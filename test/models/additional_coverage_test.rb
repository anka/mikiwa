require "test_helper"

class AdditionalCoverageTest < ActiveSupport::TestCase
  # Group model
  test "group with optional color and description" do
    g = Group.create!(name: "Schmetterlinge", color: "#FF6B6B", description: "Unsere kleinste Gruppe")
    assert_equal "#FF6B6B", g.color
    assert_equal "Unsere kleinste Gruppe", g.description
  end

  # KindergartenYear model
  test "kindergarten year without active=true is not active" do
    year = KindergartenYear.create!(
      label:      "KGJ 2024/25",
      start_date: Date.new(2024, 9, 1),
      end_date:   Date.new(2025, 7, 31),
      active:     false
    )
    assert_not year.active?
  end

  # User model role helpers
  test "User admin? caretaker? parent? helpers" do
    admin    = User.create!(email: "a@t.com", password: "sicherespasswort1234", role: "admin")
    caretaker = User.create!(email: "b@t.com", password: "sicherespasswort1234", role: "caretaker")
    parent   = User.create!(email: "c@t.com", password: SecureRandom.hex(20), role: "parent")

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
  test "User email_invalid default is false" do
    user = User.create!(email: "new@test.com", password: "sicherespasswort1234")
    assert_not user.email_invalid?
  end

  # ApplicationPolicy Scope
  test "ApplicationPolicy::Scope raises NotImplementedError" do
    user = User.create!(email: "scope@test.com", password: "sicherespasswort1234")
    scope = ApplicationPolicy::Scope.new(user, User)
    assert_raises(NotImplementedError) { scope.resolve }
  end

  # MagicLink Mailer
  test "MagicLinkMailer login has both variants" do
    parent = User.create!(email: "ml@test.com", password: SecureRandom.hex(20), role: "parent")
    mail = MagicLinkMailer.login(parent)
    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html"
    assert_includes content_types, "text/plain"
    assert_equal [ parent.email ], mail.to
  end

  # User invalidate_magic_link_token!
  test "invalidate_magic_link_token! increments version" do
    user = User.create!(email: "inv@test.com", password: SecureRandom.hex(20), role: "parent")
    original_version = user.magic_link_token_version
    user.invalidate_magic_link_token!
    assert_equal original_version + 1, user.reload.magic_link_token_version
  end

  # ImageAttachable VARIANT_CONFIGS
  test "ImageAttachable has all three variants configured" do
    assert ImageAttachable::VARIANT_CONFIGS.key?(:thumb)
    assert ImageAttachable::VARIANT_CONFIGS.key?(:display)
    assert ImageAttachable::VARIANT_CONFIGS.key?(:original)
    assert_equal :webp, ImageAttachable::VARIANT_CONFIGS[:thumb][:format]
    assert_equal :webp, ImageAttachable::VARIANT_CONFIGS[:display][:format]
  end
end
