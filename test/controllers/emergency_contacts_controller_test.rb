require "test_helper"

class EmergencyContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker    = User.create!(email: "betreuer_nk@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent       = User.create!(email: "eltern_nk@mikiwa.at",   password: SecureRandom.hex(20),   role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @other_parent = User.create!(email: "other_nk@mikiwa.at",    password: SecureRandom.hex(20),   role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 001")
    @group = Group.create!(name: "Sterne")
    @year  = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @child = Child.create!(
      first_name: "Tom", last_name: "Klein",
      date_of_birth: Date.new(2021, 4, 1),
      group: @group, kindergarten_year: @year,
      photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)
    @ec = EmergencyContact.create!(child: @child, name: "Anna Klein", relationship: "Mutter", phone: "+43 664 999", position: 1)
  end

  test "caretaker can create emergency contact" do
    sign_in_as(@caretaker)
    assert_difference "EmergencyContact.count", 1 do
      post child_emergency_contacts_path(@child), params: {
        emergency_contact: { name: "Opa", relationship: "Großvater", phone: "+43 650 123", position: 2 }
      }
    end
    assert_redirected_to child_path(@child)
  end

  test "parent can create emergency contact for own child" do
    sign_in_as(@parent)
    assert_difference "EmergencyContact.count", 1 do
      post child_emergency_contacts_path(@child), params: {
        emergency_contact: { name: "Opa", relationship: "Großvater", phone: "+43 650 123", position: 2 }
      }
    end
    assert_redirected_to child_path(@child)
  end

  test "parent has no access to other child (403)" do
    sign_in_as(@other_parent)
    post child_emergency_contacts_path(@child), params: {
      emergency_contact: { name: "X", relationship: "X", phone: "X", position: 1 }
    }
    assert_response :forbidden
  end

  test "invalid data returns error render" do
    sign_in_as(@caretaker)
    assert_no_difference "EmergencyContact.count" do
      post child_emergency_contacts_path(@child), params: {
        emergency_contact: { name: "", relationship: "", phone: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "caretaker can update emergency contact" do
    sign_in_as(@caretaker)
    patch child_emergency_contact_path(@child, @ec), params: {
      emergency_contact: { name: "Anna K. (aktualisiert)" }
    }
    assert_redirected_to child_path(@child)
    assert_equal "Anna K. (aktualisiert)", @ec.reload.name
  end

  test "caretaker can delete emergency contact" do
    sign_in_as(@caretaker)
    assert_difference "EmergencyContact.count", -1 do
      delete child_emergency_contact_path(@child, @ec)
    end
    assert_redirected_to child_path(@child)
  end
end
