require "test_helper"

class ChildrenControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_k@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "eltern2@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @group = Group.create!(name: "Löwen")
    @year = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @child = Child.create!(
      first_name:        "Finn",
      last_name:         "Berger",
      date_of_birth:     Date.new(2021, 5, 10),
      group:             @group,
      kindergarten_year: @year,
      photo_consent:     true
    )
    ParentChild.create!(user: @parent, child: @child)
  end

  test "caretaker can access children list" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
  end

  test "parent sees only own children" do
    sign_in_as(@parent)
    other_child = Child.create!(
      first_name: "Julia", last_name: "Stern",
      date_of_birth: Date.new(2022, 1, 1),
      group: @group, kindergarten_year: @year,
      photo_consent: false
    )
    get children_path
    assert_match "Finn", response.body
    assert_no_match "Julia", response.body
  end

  test "caretaker can create child" do
    sign_in_as(@caretaker)
    assert_difference "Child.count", 1 do
      post children_path, params: {
        child: {
          first_name:           "Eva",
          last_name:            "Müller",
          date_of_birth:        "2022-04-01",
          group_id:             @group.id,
          kindergarten_year_id: @year.id,
          photo_consent:        "1"
        }
      }
    end
    assert_redirected_to children_path
  end

  test "child without required fields is rejected" do
    sign_in_as(@caretaker)
    assert_no_difference "Child.count" do
      post children_path, params: {
        child: { first_name: "Eva", last_name: "Müller" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "caretaker can deactivate child" do
    sign_in_as(@caretaker)
    patch deactivate_child_path(@child)
    assert_not @child.reload.active?
    assert_redirected_to children_path
  end

  test "parent cannot deactivate child (403)" do
    sign_in_as(@parent)
    patch deactivate_child_path(@child)
    assert_response :forbidden
  end

  # F19 – Eltern-Zuordnung in Kind-Show-View
  test "caretaker can attach parent to child" do
    sign_in_as(@caretaker)
    new_parent = User.create!(email: "neu_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent")

    assert_difference "ParentChild.count", 1 do
      post attach_parent_child_path(@child), params: { user_id: new_parent.id }
    end
    assert_redirected_to child_path(@child)
    assert @child.parents.include?(new_parent)
  end

  test "caretaker can detach parent from child" do
    sign_in_as(@caretaker)

    assert_difference "ParentChild.count", -1 do
      delete detach_parent_child_path(@child, user_id: @parent.id)
    end
    assert_redirected_to child_path(@child)
    assert_not @child.reload.parents.include?(@parent)
  end

  test "attach_parent forbidden for parent role (403)" do
    sign_in_as(@parent)
    other_parent = User.create!(email: "andere_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent")

    assert_no_difference "ParentChild.count" do
      post attach_parent_child_path(@child), params: { user_id: other_parent.id }
    end
    assert_response :forbidden
  end

  test "detach_parent forbidden for parent role (403)" do
    sign_in_as(@parent)

    assert_no_difference "ParentChild.count" do
      delete detach_parent_child_path(@child, user_id: @parent.id)
    end
    assert_response :forbidden
  end

  test "attach_parent rejects non-parent user with error" do
    sign_in_as(@caretaker)
    staff_user = User.create!(email: "staffel@mikiwa.at", password: SecureRandom.hex(20), role: "caretaker")

    assert_no_difference "ParentChild.count" do
      post attach_parent_child_path(@child), params: { user_id: staff_user.id }
    end
    assert_redirected_to child_path(@child)
    assert_match(/Kein passendes Eltern-Konto/i, flash[:alert].to_s)
  end

  test "attach_parent is idempotent for already-linked parent" do
    sign_in_as(@caretaker)

    assert_no_difference "ParentChild.count" do
      post attach_parent_child_path(@child), params: { user_id: @parent.id }
    end
    assert_redirected_to child_path(@child)
  end

  test "edit form contains no parent_id select" do
    sign_in_as(@caretaker)
    get edit_child_path(@child)
    assert_response :success
    assert_no_match(/name="child\[parent_id\]"/, response.body)
  end

  test "new form keeps parent_id select" do
    sign_in_as(@caretaker)
    get new_child_path
    assert_response :success
    assert_match(/name="child\[parent_id\]"/, response.body)
  end
end
