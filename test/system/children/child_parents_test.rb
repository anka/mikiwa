require "test_helper"

class ChildParentsTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Eltern-Block-Gruppe")
    @caretaker = User.create!(
      email: "elternblock_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker",
      first_name: "Sara", last_name: "Müller"
    )
    @parent = User.create!(
      email: "elternblock_parent@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Lina", last_name: "Wagner", phone: "0664 111 222"
    )
    @other_parent = User.create!(
      email: "elternblock_other@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Tobias", last_name: "Vogel", phone: "0664 333 444"
    )
    @child = Child.create!(
      first_name: "Mila", last_name: "Wagner",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
  end

  teardown do
    @child.destroy!
    [ @parent, @other_parent, @caretaker ].each(&:destroy!)
    @group.destroy!
  end

  test "Show-View zeigt Eltern-Block mit Empty-State wenn keine Eltern zugeordnet" do
    sign_in_as(@caretaker)
    get child_path(@child)
    assert_response :success
    assert_match "Eltern", response.body
    assert_match "Keine Eltern zugeordnet", response.body
    assert_match "data-test=\"attach-parent-form\"", response.body
  end

  test "Caretaker kann Elternteil hinzufügen aus der Show-View" do
    sign_in_as(@caretaker)

    assert_difference "ParentChild.count", 1 do
      post attach_parent_child_path(@child), params: { user_id: @parent.id }
    end
    assert_redirected_to child_path(@child)

    follow_redirect!
    assert_match "Lina Wagner", response.body
  end

  test "Caretaker kann Elternteil entfernen aus der Show-View" do
    ParentChild.create!(user: @parent, child: @child)
    sign_in_as(@caretaker)

    assert_difference "ParentChild.count", -1 do
      delete detach_parent_child_path(@child, user_id: @parent.id)
    end
    assert_redirected_to child_path(@child)

    follow_redirect!
    assert_match "Keine Eltern zugeordnet", response.body
    assert_no_match(/data-test="parent-row-#{@parent.id}"/, response.body)
  end

  test "Hinweis 'Alle Eltern bereits zugeordnet' wenn keine offenen Eltern verfügbar sind" do
    ParentChild.create!(user: @parent,       child: @child)
    ParentChild.create!(user: @other_parent, child: @child)
    sign_in_as(@caretaker)

    get child_path(@child)
    assert_response :success
    assert_match "Alle Eltern bereits zugeordnet", response.body
    assert_no_match "data-test=\"attach-parent-form\"", response.body
  end

  test "Edit-Formular enthält keinen Eltern-Block und verlinkt zurück zur Show-Seite" do
    sign_in_as(@caretaker)
    get edit_child_path(@child)
    assert_response :success
    assert_no_match(/name="child\[parent_id\]"/, response.body)
    assert_match child_path(@child), response.body
  end
end
