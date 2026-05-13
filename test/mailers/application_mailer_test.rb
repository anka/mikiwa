require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  setup do
    @parent = User.create!(
      email: "mailer_test_parent@test.de",
      password: "sicherespasswort1234",
      role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000"
    )
    @admin = User.create!(
      email: "mailer_test_admin@test.de",
      password: "adminpasswort1234567",
      role: "admin"
    )
    @caretaker = User.create!(
      email: "mailer_test_caretaker@test.de",
      password: "sicherespasswort1234",
      role: "caretaker",
      invited_by: @admin
    )
  end

  teardown do
    @parent.destroy!
    @caretaker.destroy!
    @admin.destroy!
  end

  # TS-008-S01: MagicLinkMailer hat HTML- und Plaintext-Teil
  test "MagicLinkMailer.login hat HTML- und Plaintext-Teil" do
    mail = MagicLinkMailer.login(@parent)

    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html", "Magic-Link-Mail fehlt HTML-Teil"
    assert_includes content_types, "text/plain", "Magic-Link-Mail fehlt Text-Teil"

    assert_not_empty mail.html_part.body.decoded
    assert_not_empty mail.text_part.body.decoded
  end

  # TS-008-S02: InvitationMailer hat HTML- und Plaintext-Teil
  test "InvitationMailer.invite hat HTML- und Plaintext-Teil" do
    mail = InvitationMailer.invite(@caretaker)

    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html", "Invitation-Mail fehlt HTML-Teil"
    assert_includes content_types, "text/plain", "Invitation-Mail fehlt Text-Teil"

    assert_not_empty mail.html_part.body.decoded
    assert_not_empty mail.text_part.body.decoded
  end

  test "PasswordsMailer.reset hat HTML- und Plaintext-Teil" do
    mail = PasswordsMailer.reset(@caretaker)

    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html"
    assert_includes content_types, "text/plain"
  end
end
