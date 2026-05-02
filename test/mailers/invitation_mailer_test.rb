require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  setup do
    @invited_by = User.create!(
      email: "adminmailer@mikiwa.at",
      password: "adminpasswort1234567",
      role: "admin",
      first_name: "Admin"
    )
    @invitee = User.create!(
      email: "neubetreuer@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "caretaker",
      first_name: "Neu",
      last_name: "Betreuer",
      invited_by: @invited_by
    )
  end

  test "invite-Mail hat Empfänger, Betreff und Magic-Link" do
    mail = InvitationMailer.invite(@invitee)

    assert_equal [ @invitee.email ], mail.to
    assert_match "Einladung", mail.subject
    assert_match "mikiwa", mail.subject.downcase
    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html"
    assert_includes content_types, "text/plain"
  end
end
