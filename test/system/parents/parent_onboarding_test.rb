require "test_helper"

class ParentOnboardingTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @caretaker = User.create!(
      email: "parent_onboard_caretaker@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    User.where(email: [ "parent_onboard_caretaker@mikiwa.at", "new.parent@mikiwa.at" ]).destroy_all
  end

  # TS-031-S01: Betreuer legt Eltern-Account an; Einladungsmail wird versendet
  test "TS-031 Betreuer legt Eltern-Account an und Einladungsmail wird versandt" do
    sign_in_as(@caretaker)

    assert_difference "User.count", 1 do
      perform_enqueued_jobs do
        post parents_path, params: {
          user: { email: "new.parent@mikiwa.at", first_name: "Eva", last_name: "Muster" }
        }
      end
    end

    assert_response :redirect

    new_parent = User.find_by(email: "new.parent@mikiwa.at")
    assert new_parent.present?
    assert_equal "parent", new_parent.role
    assert new_parent.invitation_sent_at.present?

    mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("new.parent@mikiwa.at") }
    assert mail.present?, "Einladungsmail muss versendet worden sein"
  end

  # TS-031-S02: Magic-Link aus Einladungsmail öffnet Session
  test "TS-031 Magic-Link aus Einladungsmail öffnet Session" do
    parent = User.create!(
      email: "magic_parent@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000",
      invited_by: @caretaker,
      invitation_sent_at: Time.current
    )

    token = parent.generate_token_for(:magic_link)
    get show_magic_links_path(token: token)

    assert_response :redirect
  ensure
    parent&.destroy!
  end
end
