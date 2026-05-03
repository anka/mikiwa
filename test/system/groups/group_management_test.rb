require "test_helper"

class GroupManagementTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "group_mgmt@mikiwa.at",
      password: "sicherespasswort1234",
      role: "caretaker"
    )
  end

  teardown do
    Group.where(name: [ "Neue Testgruppe", "Farbengruppe" ]).destroy_all
    @caretaker.destroy!
  end

  # TS-026-S01: Gruppe mit Name anlegen – erscheint in Übersicht
  test "TS-026 Betreuer legt Gruppe an und sie erscheint in der Übersicht" do
    sign_in_as(@caretaker)

    post groups_path, params: { group: { name: "Neue Testgruppe", color: "#ff0000", description: "Testbeschreibung" } }

    assert_response :redirect
    follow_redirect!

    assert_match "Neue Testgruppe", response.body
    assert Group.exists?(name: "Neue Testgruppe")
  end

  # TS-026-S02: Gruppe ohne Name – Validierungsfehler
  test "TS-026 Gruppe ohne Name wird abgewiesen" do
    sign_in_as(@caretaker)

    assert_no_difference "Group.count" do
      post groups_path, params: { group: { name: "" } }
    end

    assert_response :unprocessable_entity
  end
end
