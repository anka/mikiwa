require "test_helper"

class ChildrenConsentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "Consent-Test-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_con@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_con@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @other  = User.create!(email: "other_con@mikiwa.at",  password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    @child = Child.create!(
      first_name: "Julia", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: false
    )
    @other_child = Child.create!(
      first_name: "Franz", last_name: "Test",
      date_of_birth: Date.new(2021, 2, 1),
      group: @group, kindergarten_year: @year, photo_consent: false
    )
    ParentChild.create!(user: @parent, child: @child)
    ParentChild.create!(user: @other, child: @other_child)
  end

  test "staff can update photo consent" do
    sign_in_as(@staff)
    patch update_consent_child_path(@child), params: { child: { photo_consent: true } }
    assert_equal true, @child.reload.photo_consent
    assert_redirected_to child_path(@child)
  end

  test "parent can update own child's photo consent" do
    sign_in_as(@parent)
    patch update_consent_child_path(@child), params: { child: { photo_consent: true } }
    assert_equal true, @child.reload.photo_consent
    assert_redirected_to child_path(@child)
  end

  test "parent cannot update other child's photo consent" do
    sign_in_as(@parent)
    patch update_consent_child_path(@other_child), params: { child: { photo_consent: true } }
    assert_response :forbidden
    assert_equal false, @other_child.reload.photo_consent
  end

  test "unauthenticated user is redirected" do
    patch update_consent_child_path(@child), params: { child: { photo_consent: true } }
    assert_response :redirect
  end
end
