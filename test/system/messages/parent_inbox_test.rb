require "test_helper"

class ParentInboxTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group_bears = Group.create!(name: "Inbox-Bären")
    @group_lions = Group.create!(name: "Inbox-Löwen")
    @caretaker = User.create!(email: "inbox_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "inbox_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    @child = Child.create!(
      first_name: "InboxKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group_bears, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @message_bears = Message.new(
      title: "Bären-Mitteilung", body: "Nur für Bären.",
      sent_by: @caretaker
    )
    @message_bears.message_groups.build(group: @group_bears)
    @message_bears.save!
    @inbox_entry = @message_bears.inbox_entries.create!(user: @parent)

    @message_lions = Message.new(
      title: "Löwen-Mitteilung", body: "Nur für Löwen.",
      sent_by: @caretaker
    )
    @message_lions.message_groups.build(group: @group_lions)
    @message_lions.save!
  end

  teardown do
    [ @message_bears, @message_lions ].each do |m|
      m.inbox_entries.destroy_all
      m.message_groups.destroy_all
      m.destroy!
    end
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group_bears.destroy!
    @group_lions.destroy!
  end

  # TS-048-S01: Mitteilung öffnen markiert sie als gelesen
  test "TS-048 Mitteilung öffnen markiert Eintrag als gelesen" do
    assert_not @inbox_entry.read?

    sign_in_as(@parent)
    get inbox_message_path(@message_bears)

    assert_response :success
    @inbox_entry.reload
    assert @inbox_entry.read?
  end

  # TS-048-S02: Mitteilung an fremde Gruppe nicht im Posteingang sichtbar
  test "TS-048 Mitteilung an fremde Gruppe erscheint nicht im Posteingang" do
    sign_in_as(@parent)
    get inbox_path

    assert_response :success
    assert_match "Bären-Mitteilung",   response.body
    assert_no_match "Löwen-Mitteilung", response.body
  end
end
