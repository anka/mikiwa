require "test_helper"

class MessageSendTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Msg-Bären")
    @caretaker = User.create!(email: "msg_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent1 = User.create!(email: "msg_parent1@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @parent2 = User.create!(email: "msg_parent2@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    @child1 = Child.create!(
      first_name: "MsgKind1", last_name: "A",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    @child2 = Child.create!(
      first_name: "MsgKind2", last_name: "B",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent1, child: @child1)
    ParentChild.create!(user: @parent2, child: @child2)
  end

  teardown do
    Message.where(sent_by: @caretaker).each do |m|
      m.inbox_entries.destroy_all
      m.message_groups.destroy_all
      m.destroy!
    end
    [ @child1, @child2 ].each do |c|
      ParentChild.where(child: c).destroy_all
      c.destroy!
    end
    @parent1.destroy!
    @parent2.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-047-S01: Betreuer sendet Mitteilung; beide Elternteile erhalten sie im Posteingang
  test "TS-047 Betreuer sendet Mitteilung an Gruppe; Eltern haben sie im Posteingang" do
    sign_in_as(@caretaker)

    perform_enqueued_jobs do
      post messages_path, params: {
        message: {
          title: "Wichtige Mitteilung",
          body: "Bitte morgen Gummistiefel mitbringen.",
          group_ids: [ @group.id ]
        }
      }
    end

    assert_response :redirect

    message = Message.find_by(title: "Wichtige Mitteilung")
    assert message.present?

    assert InboxEntry.exists?(message: message, user: @parent1)
    assert InboxEntry.exists?(message: message, user: @parent2)

    assert_equal 2, ActionMailer::Base.deliveries.count { |m| m.subject&.include?("Wichtige Mitteilung") }
  end
end
