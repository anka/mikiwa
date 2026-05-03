require "test_helper"

class ChildCreationTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Child-Creation-Gruppe")
    @caretaker = User.create!(
      email: "child_create@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    Child.where(last_name: "Testrubrik").each { |c| c.medical_notes.destroy_all; c.destroy! }
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-028-S01: Kind mit allen Pflichtfeldern anlegen
  test "TS-028 Betreuer legt Kind mit Pflichtfeldern an" do
    sign_in_as(@caretaker)

    assert_difference "Child.count", 1 do
      post children_path, params: {
        child: {
          first_name: "Max",
          last_name: "Testrubrik",
          date_of_birth: "2020-05-15",
          group_id: @group.id,
          kindergarten_year_id: @year.id,
          photo_consent: true
        }
      }
    end

    assert_response :redirect
  end

  # TS-028-S02: Kind ohne Geburtsdatum wird abgewiesen
  test "TS-028 Kind ohne Geburtsdatum wird abgewiesen" do
    sign_in_as(@caretaker)

    assert_no_difference "Child.count" do
      post children_path, params: {
        child: {
          first_name: "Max",
          last_name: "Testrubrik",
          group_id: @group.id,
          kindergarten_year_id: @year.id,
          photo_consent: true
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # TS-028-S03: Kind ohne photo_consent wird abgewiesen
  test "TS-028 Kind ohne photo_consent-Angabe wird abgewiesen" do
    sign_in_as(@caretaker)

    assert_no_difference "Child.count" do
      post children_path, params: {
        child: {
          first_name: "Max",
          last_name: "Testrubrik",
          date_of_birth: "2020-05-15",
          group_id: @group.id,
          kindergarten_year_id: @year.id
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
