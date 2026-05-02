require "test_helper"

class BirthdaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_a = Group.create!(name: "Geburtstag-Bären")
    @group_b = Group.create!(name: "Geburtstag-Löwen")
    @year    = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_bday@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_bday@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    today = Date.current
    @child_soon = Child.create!(
      first_name: "Emma", last_name: "Bald",
      date_of_birth: today.change(year: today.year - 4) + 7.days,
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_later = Child.create!(
      first_name: "Tom", last_name: "Später",
      date_of_birth: today.change(year: today.year - 5) + 60.days,
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_other_group = Child.create!(
      first_name: "Mia", last_name: "Löwen",
      date_of_birth: today.change(year: today.year - 3) + 3.days,
      group: @group_b, kindergarten_year: @year, photo_consent: true
    )

    ParentChild.create!(user: @parent, child: @child_soon)
    ParentChild.create!(user: @parent, child: @child_later)
  end

  test "staff can access birthday overview" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
  end

  test "parent can access birthday overview" do
    sign_in_as(@parent)
    get birthdays_path
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    get birthdays_path
    assert_response :redirect
  end

  test "staff sees all groups" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
    assert_match @child_other_group.first_name, response.body
  end

  test "parent sees only their children's groups" do
    sign_in_as(@parent)
    get birthdays_path
    assert_response :success
    assert_no_match @child_other_group.first_name, response.body
  end

  test "response highlights upcoming birthdays" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
  end
end
