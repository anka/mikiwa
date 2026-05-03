require "test_helper"

class YearRolloverTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "rollover_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @group = Group.create!(name: "Rollover-Gruppe")

    @year_old = KindergartenYear.create!(
      label: "2025/26-RO", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @year_new = KindergartenYear.create!(
      label: "2026/27-RO", start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 7, 31), active: false
    )

    @child_a = Child.create!(
      first_name: "RO-Kind", last_name: "A", date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year_old, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "RO-Kind", last_name: "B", date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year_old, photo_consent: true
    )
  end

  teardown do
    Child.where(kindergarten_year: [ @year_old, @year_new ]).destroy_all
    @year_new.destroy!
    @year_old.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-027-S01: Kinder werden ins neue Jahr übernommen; Galerie bleibt beim alten Jahr
  test "TS-027 Jahresübergang überträgt ausgewählte Kinder ins neue Jahr" do
    sign_in_as(@caretaker)

    post execute_rollover_kindergarten_year_path(@year_new), params: {
      child_ids: [ @child_a.id, @child_b.id ]
    }

    assert_response :redirect

    new_children = Child.where(kindergarten_year: @year_new)
    assert_equal 2, new_children.count

    new_a = new_children.find_by(last_name: "A")
    assert new_a.present?
    assert new_a.active?

    @year_new.reload
    assert @year_new.active?, "Neues Jahr muss nach Rollover aktiv sein"
  end

  test "TS-027 Notfallkontakte werden beim Jahresübergang kopiert" do
    @child_a.emergency_contacts.create!(
      name: "Notfallkontakt Rollover",
      relationship: "Oma",
      phone: "+43 664 1234567",
      position: 1
    )

    sign_in_as(@caretaker)
    post execute_rollover_kindergarten_year_path(@year_new), params: {
      child_ids: [ @child_a.id ]
    }

    new_child = Child.find_by(last_name: "A", kindergarten_year: @year_new)
    assert new_child.emergency_contacts.any? { |ec| ec.name == "Notfallkontakt Rollover" }
  end
end
