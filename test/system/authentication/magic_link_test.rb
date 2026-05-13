require "test_helper"

class MagicLinkSystemTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    @parent = User.create!(
      email: "parent_magic@test.de",
      password: "sicherespasswort1234",
      role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000"
    )
  end

  teardown do
    ActionMailer::Base.deliveries.clear
    @parent.destroy!
  end

  # TS-003-S01: vollständiger Magic-Link-Flow
  test "Magic Link vollständiger Flow: anfordern, Token aus Mail, einloggen" do
    perform_enqueued_jobs do
      post magic_links_path, params: { email: @parent.email }
    end

    assert_equal 1, ActionMailer::Base.deliveries.size

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@parent.email], mail.to

    mail_text = mail.text_part&.body&.decoded || mail.body.decoded
    url = mail_text[/https?:\/\/[^\s]+\/magic_links\/[^\s]+/]
    assert_not_nil url, "Kein Magic-Link in der E-Mail gefunden"
    token = url[%r{/magic_links/([^\s?]+)}, 1]
    assert_not_nil token, "Kein Token in der E-Mail-URL gefunden"

    get show_magic_links_path(token: token)

    assert_redirected_to parent_dashboard_path
    assert_equal 1, @parent.reload.sessions.count

    follow_redirect!
    assert_response :success
  end

  # TS-003-S02: Unbekannte E-Mail – neutrale Meldung, keine E-Mail
  test "Unbekannte E-Mail zeigt neutrale Bestätigung und sendet keine E-Mail" do
    perform_enqueued_jobs do
      post magic_links_path, params: { email: "nicht.vorhanden@test.de" }
    end

    assert_redirected_to new_session_path
    follow_redirect!
    assert_match(/Falls ein Konto mit dieser E-Mail-Adresse existiert/, response.body)
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
end
