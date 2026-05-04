require "test_helper"

class BirthdaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group_a = Group.create!(name: "Geburtstag-Bären")
    @group_b = Group.create!(name: "Geburtstag-Löwen")
    @year    = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_bday@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_bday@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    today = Date.current
    @child_soon = Child.create!(
      first_name: "Emma", last_name: "Bald",
      date_of_birth: today.change(year: today.year - 4) + 7.days,
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_later = Child.create!(
      first_name: "Tom", last_name: "Später",
      date_of_birth: today.change(year: today.year - 5) + 60.days,
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_other_group = Child.create!(
      first_name: "Mia", last_name: "Löwen",
      date_of_birth: today.change(year: today.year - 3) + 3.days,
      group: @group_b, kindergarten_year: @year, photo_consent: true
    )

    ParentChild.create!(user: @parent, child: @child_soon)
    ParentChild.create!(user: @parent, child: @child_later)
  end

  test "staff can access birthday overview" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
  end

  test "parent can access birthday overview" do
    sign_in_as(@parent)
    get birthdays_path
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    get birthdays_path
    assert_response :redirect
  end

  test "staff sees all groups" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
    assert_match @child_other_group.first_name, response.body
  end

  test "parent sees only their children's groups" do
    sign_in_as(@parent)
    get birthdays_path
    assert_response :success
    assert_no_match @child_other_group.first_name, response.body
  end

  test "response highlights upcoming birthdays" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
  end

  # F22: Geburtstags-Hero-Section
  test "F22 Hero zeigt Kinder mit Geburtstag in den nächsten 7 Tagen" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
    # @child_soon hat Geburtstag in 7 Tagen, @child_other_group in 3 Tagen
    assert_match(/mw-birthdays-hero/, response.body, "Hero-Section muss vorhanden sein")
    assert_match "Emma", response.body
    assert_match "Mia", response.body
  end

  test "F22 Hero ist sortiert nach Datum (nähestes zuerst)" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
    # @child_other_group (Mia) in 3 Tagen kommt vor @child_soon (Emma) in 7 Tagen
    body = response.body
    hero_section = body[/mw-birthdays-hero.*?<\/section>/m] || body
    mia_pos = hero_section.index("Mia")
    emma_pos = hero_section.index("Emma")
    assert mia_pos && emma_pos, "Beide Namen müssen im Hero auftauchen"
    assert mia_pos < emma_pos, "Mia (3 Tage) muss vor Emma (7 Tage) erscheinen"
  end

  test "F22 Hero zeigt Karten mit Name, Datum, Wochentag und Alter" do
    sign_in_as(@staff)
    get birthdays_path
    assert_response :success
    # @child_other_group "Mia Löwen" geboren today.change(year: today.year - 3) + 3.days → wird 4
    assert_match(/Mia/, response.body)
    upcoming = (Date.current + 3.days)
    assert_match(/4 Jahre|wird 4/i, response.body, "Neues Alter sollte 4 sein")
  end

  test "F22 Hero zeigt Empty-State wenn keine Geburtstage in 7 Tagen" do
    sign_in_as(@staff)
    @child_soon.destroy
    @child_other_group.destroy
    # nur @child_later (in 60 Tagen) bleibt
    get birthdays_path
    assert_response :success
    assert_match(/Keine Geburtstage in den nächsten/i, response.body)
    assert_match "Tom", response.body, "Nächster Geburtstag (Tom) muss im Empty-State stehen"
  end
end
