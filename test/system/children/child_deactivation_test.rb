require "test_helper"

class ChildDeactivationTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Deactivation-Gruppe")
    @caretaker = User.create!(
      email: "deactivation@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
    @child = Child.create!(
      first_name: "Kind", last_name: "Deaktivierbar",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
  end

  teardown do
    @child.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-030-S01: Deaktiviertes Kind erscheint nicht in aktiver Kinderliste
  test "TS-030 deaktiviertes Kind erscheint nicht mehr in der Kinderliste" do
    sign_in_as(@caretaker)

    patch deactivate_child_path(@child)
    assert_response :redirect
    follow_redirect!

    @child.reload
    assert_not @child.active?, "Kind muss deaktiviert sein"

    get children_path
    assert_response :success
    assert_no_match "Deaktivierbar", response.body
  end
end
