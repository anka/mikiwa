require "test_helper"

class ParentScopingTest < ActionDispatch::IntegrationTest
  setup do
    year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    group = Group.create!(name: "Bären")

    @parent_a = User.create!(email: "parent_a@scope.de", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @parent_b = User.create!(email: "parent_b@scope.de", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    @child_x = Child.create!(
      first_name: "Kind", last_name: "X", date_of_birth: 5.years.ago.to_date,
      group: group, kindergarten_year: year, photo_consent: true
    )
    @child_y = Child.create!(
      first_name: "Kind", last_name: "Y", date_of_birth: 5.years.ago.to_date,
      group: group, kindergarten_year: year, photo_consent: true
    )

    ParentChild.create!(user: @parent_a, child: @child_x)
    ParentChild.create!(user: @parent_b, child: @child_y)
  end

  teardown do
    ParentChild.where(user: [@parent_a, @parent_b]).destroy_all
    @child_x.destroy!
    @child_y.destroy!
    @parent_a.destroy!
    @parent_b.destroy!
  end

  # TS-010-S01: Elternteil sieht nur eigene Kinder
  test "Elternteil sieht nur eigene Kinder in der Index-Liste" do
    sign_in_as(@parent_a)

    get children_path

    assert_response :success
    assert_match "Kind #{@child_x.last_name}", response.body
    assert_no_match "Kind #{@child_y.last_name}", response.body
  end

  # TS-010-S02: Direktzugriff auf fremdes Kind → 403
  test "Elternteil kann nicht auf fremdes Kind zugreifen" do
    sign_in_as(@parent_a)

    get child_path(@child_y)

    assert_response :forbidden
  end
end
