require "test_helper"

class UserManagementTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = User.create!(
      email: "admin_mgmt@mikiwa.at",
      password: "sicherespasswort1234",
      role: "admin"
    )
  end

  teardown do
    User.where(email: [ "admin_mgmt@mikiwa.at", "neu.betreuer@mikiwa.at" ]).destroy_all
  end

  # TS-023-S01: Admin lädt neuen Betreuer ein
  test "TS-023 Admin lädt neuen Betreuer ein und Einladungsmail wird versendet" do
    sign_in_as(@admin)

    assert_difference "User.count", 1 do
      perform_enqueued_jobs do
        post admin_users_path, params: {
          user: { email: "neu.betreuer@mikiwa.at", role: "caretaker" }
        }
      end
    end

    assert_response :redirect
    new_user = User.find_by(email: "neu.betreuer@mikiwa.at")
    assert new_user.present?
    assert_equal "caretaker", new_user.role
    assert new_user.invitation_sent_at.present?

    mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("neu.betreuer@mikiwa.at") }
    assert mail.present?, "Einladungsmail muss versendet worden sein"
  end
end
