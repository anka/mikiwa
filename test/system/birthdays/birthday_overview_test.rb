require "test_helper"

class BirthdayOverviewTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group_bears = Group.create!(name: "Bday-Bären")
    @group_lions = Group.create!(name: "Bday-Löwen")
    @caretaker = User.create!(email: "bday_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "bday_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    today = Date.new(2026, 5, 3)

    @child_soon = Child.create!(
      first_name: "BaldGeburtstag", last_name: "A",
      date_of_birth: today.change(year: 2021) + 7.days,
      group: @group_bears, kindergarten_year: @year, photo_consent: true
    )
    @child_later = Child.create!(
      first_name: "SpätGeburtstag", last_name: "B",
      date_of_birth: today.change(year: 2021) + 30.days,
      group: @group_lions, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child_soon)
  end

  teardown do
    ParentChild.where(user: @parent).destroy_all
    [ @child_soon, @child_later ].each(&:destroy!)
    @parent.destroy!
    @caretaker.destroy!
    @group_bears.destroy!
    @group_lions.destroy!
  end

  # TS-050-S01: Hervorhebung: Kind mit Geburtstag in 7 Tagen hervorgehoben, 30 Tage nicht
  test "TS-050 Kind mit baldige Geburtstag ist hervorgehoben" do
    travel_to Date.new(2026, 5, 3) do
      sign_in_as(@caretaker)
      get birthdays_path

      assert_response :success
      assert_match "mw-table-row--highlight", response.body
      assert_match "BaldGeburtstag", response.body
    end
  end

  # TS-050-S02: Elternteile haben keinen Zugriff auf die Geburtstagsübersicht
  test "TS-050 Elternteil ist von der Geburtstagsübersicht ausgeschlossen" do
    travel_to Date.new(2026, 5, 3) do
      sign_in_as(@parent)
      get birthdays_path

      assert_response :forbidden
    end
  end
end
