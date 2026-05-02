require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @group_a = Group.create!(name: "Mitteilungs-Bären")
    @group_b = Group.create!(name: "Mitteilungs-Löwen")
    @staff   = User.create!(email: "staff_msg@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent_a = User.create!(email: "parent_msg_a@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @parent_b = User.create!(email: "parent_msg_b@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @year = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @child_a = Child.create!(
      first_name: "Max", last_name: "Muster",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent_a, child: @child_a)

    @message = Message.new(title: "Wichtige Info", body: "Bitte lesen.", sent_by: @staff)
    @message.message_groups.build(group: @group_a)
  end

  test "valid message can be saved" do
    assert @message.save, @message.errors.full_messages.inspect
  end

  test "uses UUID primary key" do
    @message.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @message.id)
  end

  test "title is required" do
    @message.title = nil
    assert_not @message.valid?
    assert @message.errors[:title].any?
  end

  test "body is required" do
    @message.body = nil
    assert_not @message.valid?
    assert @message.errors[:body].any?
  end

  test "at least one group required" do
    msg = Message.new(title: "Leer", body: "Text", sent_by: @staff)
    assert_not msg.valid?
    assert msg.errors[:message_groups].any?
  end

  test "deliver! creates inbox entries for group members" do
    @message.save!
    assert_difference "InboxEntry.count", 1 do
      @message.deliver!
    end
    assert InboxEntry.exists?(message: @message, user: @parent_a)
  end

  test "deliver! does not create duplicate inbox entries" do
    @message.save!
    @message.deliver!
    assert_no_difference "InboxEntry.count" do
      @message.deliver!
    end
  end

  test "ordered scope sorts by created_at desc" do
    @message.save!
    msg2 = Message.new(title: "Zweite", body: "Text", sent_by: @staff)
    msg2.message_groups.build(group: @group_a)
    msg2.save!
    assert_equal msg2.id, Message.ordered.first.id
  end
end
