require "test_helper"

class ParentDashboardIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group_a = Group.create!(name: "DashIso-Bären")
    @group_b = Group.create!(name: "DashIso-Löwen")
    @caretaker = User.create!(email: "dashiso_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent_a = User.create!(email: "dashiso_pa@mikiwa.at", password: "sicherespasswort1234", role: "parent")
    @parent_b = User.create!(email: "dashiso_pb@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    @child_a = Child.create!(
      first_name: "IsoKind", last_name: "A",
      date_of_birth: 5.years.ago.to_date,
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "IsoKind", last_name: "B",
      date_of_birth: 4.years.ago.to_date,
      group: @group_b, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent_a, child: @child_a)
    ParentChild.create!(user: @parent_b, child: @child_b)

    @msg_a = Message.new(
      title: "Nur für Bären", body: "Nachricht A.", sent_by: @caretaker
    )
    @msg_a.message_groups.build(group: @group_a)
    @msg_a.save!
    @msg_a.inbox_entries.create!(user: @parent_a)
  end

  teardown do
    @msg_a.inbox_entries.destroy_all
    @msg_a.message_groups.destroy_all
    @msg_a.destroy!
    ParentChild.where(user: [ @parent_a, @parent_b ]).destroy_all
    @child_a.destroy!
    @child_b.destroy!
    @parent_a.destroy!
    @parent_b.destroy!
    @caretaker.destroy!
    @group_a.destroy!
    @group_b.destroy!
  end

  # TS-057-S01: Elternteil B sieht keine Mitteilung, die nur an Gruppe A geschickt wurde
  test "TS-057 Dashboard zeigt keine Mitteilungen aus fremden Gruppen" do
    sign_in_as(@parent_b)
    get parent_dashboard_path

    assert_response :success
    assert_no_match "Nur für Bären", response.body
  end
end
