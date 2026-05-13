require "test_helper"

class EmergencyContactAccessTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "EC-Access-Gruppe")

    @parent_a = User.create!(email: "ec_parent_a@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @parent_b = User.create!(email: "ec_parent_b@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    @child_a = Child.create!(
      first_name: "Kind", last_name: "ECA",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "Kind", last_name: "ECB",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )

    ParentChild.create!(user: @parent_a, child: @child_a)
    ParentChild.create!(user: @parent_b, child: @child_b)

    @ec_b = EmergencyContact.create!(
      child: @child_b, name: "Fremd-Kontakt", relationship: "Vater",
      phone: "+43 111 111111", position: 1
    )
  end

  teardown do
    @ec_b.destroy!
    ParentChild.where(user: [ @parent_a, @parent_b ]).destroy_all
    @child_a.destroy!
    @child_b.destroy!
    @parent_a.destroy!
    @parent_b.destroy!
    @group.destroy!
  end

  # TS-034-S01: Elternteil kann Notfallkontakte fremder Kinder nicht lesen
  test "TS-034 Elternteil kann keine Notfallkontakte fremder Kinder anlegen" do
    sign_in_as(@parent_a)

    post child_emergency_contacts_path(@child_b), params: {
      emergency_contact: {
        name: "Unerlaubt", relationship: "Fremder", phone: "+43 000 000000", position: 1
      }
    }

    assert_response :forbidden
  end

  test "TS-034 Elternteil kann Notfallkontakte eigenes Kind anlegen" do
    sign_in_as(@parent_a)

    assert_difference "EmergencyContact.count", 1 do
      post child_emergency_contacts_path(@child_a), params: {
        emergency_contact: {
          name: "Eigener Kontakt", relationship: "Oma", phone: "+43 664 9999999", position: 1
        }
      }
    end

    assert_response :redirect
  end
end
