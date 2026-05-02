require "test_helper"

class KindergartenYearsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin_kgj@mikiwa.at", password: "adminpasswort1234567", role: "admin")
    @caretaker = User.create!(email: "betreuer_kgj@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @active_year = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @past_year = KindergartenYear.create!(
      label:      "KGJ 2024/25",
      start_date: Date.new(2024, 9, 1),
      end_date:   Date.new(2025, 7, 31),
      active:     false
    )
  end

  test "caretaker can access kindergarten years list" do
    sign_in_as(@caretaker)
    get kindergarten_years_path
    assert_response :success
  end

  test "create new kindergarten year" do
    sign_in_as(@caretaker)
    assert_difference "KindergartenYear.count", 1 do
      post kindergarten_years_path, params: {
        kindergarten_year: {
          label:      "KGJ 2026/27",
          start_date: "2026-09-01",
          end_date:   "2027-07-31"
        }
      }
    end
    assert_redirected_to kindergarten_years_path
  end

  test "activate year deactivates previous year" do
    sign_in_as(@caretaker)
    new_year = KindergartenYear.create!(
      label:      "KGJ 2026/27",
      start_date: Date.new(2026, 9, 1),
      end_date:   Date.new(2027, 7, 31),
      active:     false
    )
    patch activate_kindergarten_year_path(new_year)
    assert new_year.reload.active?
    assert_not @active_year.reload.active?
  end

  test "caretaker sees all kindergarten years" do
    sign_in_as(@caretaker)
    get kindergarten_years_path
    assert_match @active_year.label, response.body
    assert_match @past_year.label, response.body
  end

  test "execute rollover without children" do
    sign_in_as(@caretaker)
    new_year = KindergartenYear.create!(
      label:      "KGJ 2026/27",
      start_date: Date.new(2026, 9, 1),
      end_date:   Date.new(2027, 7, 31),
      active:     false
    )
    post execute_rollover_kindergarten_year_path(new_year), params: { child_ids: [] }
    assert new_year.reload.active?
    assert_redirected_to kindergarten_years_path
  end

  test "rollover form is reachable for caretaker" do
    sign_in_as(@caretaker)
    new_year = KindergartenYear.create!(
      label:      "KGJ 2026/27",
      start_date: Date.new(2026, 9, 1),
      end_date:   Date.new(2027, 7, 31),
      active:     false
    )
    get rollover_kindergarten_year_path(new_year)
    assert_response :success
  end
end
