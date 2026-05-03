require "test_helper"

class ChildCrudTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "CRUD-Gruppe")
    @caretaker = User.create!(
      email: "crud_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @child = Child.create!(
      first_name: "MaxiKind", last_name: "Müller",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
  end

  teardown do
    @child.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-063-S01: Spitzname bearbeiten → im Profil sichtbar
  test "TS-063 Betreuer kann Spitzname eines Kindes bearbeiten" do
    sign_in_as(@caretaker)

    patch child_path(@child), params: {
      child: {
        first_name: @child.first_name,
        last_name: @child.last_name,
        date_of_birth: @child.date_of_birth,
        group_id: @group.id,
        kindergarten_year_id: @year.id,
        photo_consent: "1",
        nickname: "Maxi"
      }
    }
    assert_response :redirect

    get child_path(@child)
    assert_response :success
    assert_match "Maxi", response.body
    assert @child.reload.updated_at > 1.minute.ago, "updated_at sollte nach Bearbeitung aktualisiert sein"
  end
end
