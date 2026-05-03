require "test_helper"

class CaretakerSentTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Gesendet-Gruppe")
    @caretaker = User.create!(
      email: "sent_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @parent = User.create!(
      email: "sent_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent"
    )
    @child = Child.create!(
      first_name: "GesendetKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @message = Message.new(title: "Gesendet-Mitteilung", body: "Test-Inhalt", sent_by: @caretaker)
    @message.message_groups.build(group: @group)
    @message.save!
    @inbox_entry = InboxEntry.create!(message: @message, user: @parent)
  end

  teardown do
    InboxEntry.where(message: @message).destroy_all if @message.persisted?
    @message.destroy! if @message.persisted?
    ParentChild.where(user: @parent, child: @child).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-069-S01: Gesendet-Bereich zeigt Mitteilung
  test "TS-069 Gesendet-Bereich zeigt versandte Mitteilung" do
    sign_in_as(@caretaker)
    get messages_path

    assert_response :success
    assert_match "Gesendet-Mitteilung", response.body
    assert_match "Gesendet-Gruppe", response.body
  end

  # Nach Löschen: Mitteilung nicht mehr in Gesendet-Bereich
  test "TS-069 Gelöschte Mitteilung erscheint nicht mehr in Gesendet-Bereich" do
    sign_in_as(@caretaker)

    delete message_path(@message)
    assert_response :redirect

    get messages_path
    assert_response :success
    assert_no_match "Gesendet-Mitteilung", response.body
  end
end
