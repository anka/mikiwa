require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(email: "test-mailer@example.com", password: "sicherespasswort1234")
    @token = "test-reset-token-12345"
    @user.stubs(:password_reset_token).returns(@token) if @user.respond_to?(:stubs)
  end

  test "delivery_method ist :test im Test-Modus" do
    assert_equal :test, ActionMailer::Base.delivery_method
  end

  test "reset-Mail hat HTML- und Plaintext-Variante" do
    mail = PasswordsMailer.reset(@user)
    content_types = mail.parts.map { |p| p.content_type.split(";").first }
    assert_includes content_types, "text/html"
    assert_includes content_types, "text/plain"
  end

  test "reset-Mail hat korrekte Empfängeradresse" do
    mail = PasswordsMailer.reset(@user)
    assert_equal [ @user.email ], mail.to
  end

  test "reset-Mail landet in deliveries ohne tatsächlich zu versenden" do
    ActionMailer::Base.deliveries.clear
    PasswordsMailer.reset(@user).deliver_now
    assert_equal 1, ActionMailer::Base.deliveries.count
    assert_equal [ @user.email ], ActionMailer::Base.deliveries.last.to
  end
end
