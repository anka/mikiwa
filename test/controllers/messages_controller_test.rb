require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group  = Group.create!(name: "Msg-Bären")
    @staff  = User.create!(email: "staff_mc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_mc@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @year   = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @child = Child.create!(
      first_name: "Lisa", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @message = Message.new(title: "Test-Info", body: "Inhalt", sent_by: @staff)
    @message.message_groups.build(group: @group)
    @message.save!
  end

  # --- index ---

  test "staff can access messages list" do
    sign_in_as(@staff)
    get messages_path
    assert_response :success
  end

  test "parent cannot access messages list" do
    sign_in_as(@parent)
    get messages_path
    assert_response :forbidden
  end

  test "unauthenticated user is redirected" do
    get messages_path
    assert_response :redirect
  end

  # --- new ---

  test "staff can open new message form" do
    sign_in_as(@staff)
    get new_message_path
    assert_response :success
  end

  test "parent cannot open new message form" do
    sign_in_as(@parent)
    get new_message_path
    assert_response :forbidden
  end

  # --- create ---

  test "staff can create and deliver message" do
    sign_in_as(@staff)
    assert_difference "Message.count", 1 do
      post messages_path, params: {
        message: {
          title: "Neue Info", body: "Text der Mitteilung",
          group_ids: [ @group.id ]
        }
      }
    end
    assert_redirected_to messages_path
    assert InboxEntry.exists?(user: @parent)
  end

  test "parent cannot create message" do
    sign_in_as(@parent)
    assert_no_difference "Message.count" do
      post messages_path, params: {
        message: { title: "Versuch", body: "Text", group_ids: [ @group.id ] }
      }
    end
    assert_response :forbidden
  end

  test "create renders new on validation error" do
    sign_in_as(@staff)
    assert_no_difference "Message.count" do
      post messages_path, params: {
        message: { title: "", body: "Text", group_ids: [ @group.id ] }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- destroy ---

  test "staff can delete message" do
    sign_in_as(@staff)
    assert_difference "Message.count", -1 do
      delete message_path(@message)
    end
    assert_redirected_to messages_path
  end

  test "parent cannot delete message" do
    sign_in_as(@parent)
    assert_no_difference "Message.count" do
      delete message_path(@message)
    end
    assert_response :forbidden
  end
end
