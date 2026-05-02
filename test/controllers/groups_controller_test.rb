require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin_g@mikiwa.at", password: "adminpasswort1234567", role: "admin")
    @caretaker = User.create!(email: "betreuer_g@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "eltern_g@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @group = Group.create!(name: "Bären")
  end

  test "caretaker can access groups list" do
    sign_in_as(@caretaker)
    get groups_path
    assert_response :success
  end

  test "parent cannot access groups list (403)" do
    sign_in_as(@parent)
    get groups_path
    assert_response :forbidden
  end

  test "caretaker can create group" do
    sign_in_as(@caretaker)
    assert_difference "Group.count", 1 do
      post groups_path, params: { group: { name: "Schmetterlinge", color: "#FF6B6B", description: "Unsere Kleinen" } }
    end
    assert_redirected_to groups_path
  end

  test "group without name is rejected" do
    sign_in_as(@caretaker)
    assert_no_difference "Group.count" do
      post groups_path, params: { group: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "caretaker can update group" do
    sign_in_as(@caretaker)
    patch group_path(@group), params: { group: { name: "Neue Bären", color: "#00AA00" } }
    assert_equal "Neue Bären", @group.reload.name
    assert_equal "#00AA00", @group.reload.color
  end

  test "caretaker can delete group" do
    sign_in_as(@caretaker)
    assert_difference "Group.count", -1 do
      delete group_path(@group)
    end
  end
end
