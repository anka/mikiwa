require "test_helper"

class KindergartenYearManagementTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(
      email: "kgj_mgmt_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @year_2526 = KindergartenYear.create!(
      label: "2025/26-Mgmt", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
  end

  teardown do
    KindergartenYear.where(label: [ "2025/26-Mgmt", "2026/27-Mgmt" ]).destroy_all
    @caretaker.destroy!
  end

  # TS-062-S01: Neues KGJ anlegen, aktivieren → altes wird inaktiv
  test "TS-062 neues Kindergartenjahr anlegen und aktivieren setzt vorheriges inaktiv" do
    sign_in_as(@caretaker)

    post kindergarten_years_path, params: {
      kindergarten_year: {
        label: "2026/27-Mgmt",
        start_date: "2026-09-01",
        end_date: "2027-07-31",
        active: "0"
      }
    }
    assert_response :redirect

    new_year = KindergartenYear.find_by!(label: "2026/27-Mgmt")
    assert_not new_year.active?, "Neues KGJ sollte anfangs inaktiv sein"

    patch activate_kindergarten_year_path(new_year)
    assert_response :redirect

    assert new_year.reload.active?, "Neues KGJ 2026/27 sollte nach Aktivierung aktiv sein"
    assert_not @year_2526.reload.active?, "Altes KGJ 2025/26 sollte nach Aktivierung inaktiv sein"
    assert KindergartenYear.find_by(label: "2025/26-Mgmt").present?, "Altes KGJ muss noch in DB vorhanden sein"
  end
end
