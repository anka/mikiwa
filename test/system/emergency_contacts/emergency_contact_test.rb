require "test_helper"

class EmergencyContactTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "EC-Test-Gruppe")
    @caretaker = User.create!(email: "ec_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @child = Child.create!(
      first_name: "EC-Kind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
  end

  teardown do
    EmergencyContact.where(child: @child).destroy_all
    @child.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-033-S01: Betreuer legt Notfallkontakt an
  test "TS-033 Betreuer legt Notfallkontakt für Kind an" do
    sign_in_as(@caretaker)

    assert_difference "EmergencyContact.count", 1 do
      post child_emergency_contacts_path(@child), params: {
        emergency_contact: {
          name: "Oma Maier",
          relationship: "Großmutter",
          phone: "+43 664 1234567",
          position: 1
        }
      }
    end

    assert_response :redirect
    assert @child.emergency_contacts.reload.any? { |ec| ec.name == "Oma Maier" }
  end
end
