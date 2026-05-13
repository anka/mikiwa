require "test_helper"

class RolloversControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_ro@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_ro@mikiwa.at",   password: SecureRandom.hex(20),   role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")

    @source = KindergartenYear.create!(label: "KGJ 25/26-RO",
      start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), status: "active")
    @target = KindergartenYear.create!(label: "KGJ 26/27-RO",
      start_date: Date.new(2026, 9, 1), end_date: Date.new(2027, 7, 31), status: "planning")

    @group_baeren = Group.create!(name: "Rollover-Bären")
    @group_loewen = Group.create!(name: "Rollover-Löwen")

    @child_a = Child.create!(first_name: "Anna", last_name: "Aaron",
      date_of_birth: 4.years.ago.to_date,
      group: @group_baeren, kindergarten_year: @source, photo_consent: true)
    @child_b = Child.create!(first_name: "Bea", last_name: "Berg",
      date_of_birth: 5.years.ago.to_date,
      group: @group_loewen, kindergarten_year: @source, photo_consent: true)
  end

  test "F55 GET /rollover ist für Caretaker erreichbar" do
    sign_in_as(@caretaker)
    get rollover_path
    assert_response :success
    assert_match(/Rollover ins neue Kindergartenjahr/, response.body)
    assert_select 'select[name="source_year_id"]'
    assert_select 'select[name="target_year_id"]'
    assert_select 'input[type="checkbox"][name="child_ids[]"]', minimum: 2
  end

  test "F55 Eltern bekommen 403 auf /rollover" do
    sign_in_as(@parent)
    get rollover_path
    assert_response :forbidden
  end

  test "F55 Filter Gruppe wirkt" do
    sign_in_as(@caretaker)
    get rollover_path, params: { group_id: @group_loewen.id }
    assert_response :success
    assert_match "Bea Berg", response.body
    assert_no_match(/Anna Aaron/, response.body)
  end

  test "F55 Auswahl bleibt beim Filtern stabil (Hidden-Field)" do
    sign_in_as(@caretaker)
    # Wähle nur Anna explizit (Bea bleibt durch hidden field nicht erhalten, weil child_ids array)
    get rollover_path, params: { group_id: @group_loewen.id, child_ids: [ @child_a.id ] }
    assert_response :success
    # Anna ist nicht im aktuellen Filter (Löwen) sichtbar, muss aber als hidden field erscheinen
    assert_select "input[type=hidden][name='child_ids[]'][value='#{@child_a.id}']"
  end

  test "F55 POST /rollover/confirm rendert Bilanz" do
    sign_in_as(@caretaker)
    post rollover_confirm_path, params: {
      source_year_id: @source.id, target_year_id: @target.id,
      child_ids: [ @child_a.id ]
    }
    assert_response :success
    assert_match "Anna Aaron", response.body
    assert_match "Bea Berg", response.body
  end

  # F56: Auto-Deaktivierung + transaktionale Ausführung
  test "F56 Execute überträgt ausgewählte Kinder und deaktiviert die anderen" do
    sign_in_as(@caretaker)
    assert_no_difference "Child.count" do
      post rollover_execute_path, params: {
        source_year_id: @source.id, target_year_id: @target.id,
        child_ids: [ @child_a.id ]
      }
    end
    assert_redirected_to children_path
    assert_match(/Rollover abgeschlossen: 1 übernommen, 1 deaktiviert/, flash[:notice])

    @child_a.reload
    @child_b.reload
    assert_equal @target.id, @child_a.kindergarten_year_id
    assert @child_a.active?
    assert_equal @source.id, @child_b.kindergarten_year_id
    assert_not @child_b.active?
  end

  test "F56 Execute ist idempotent bei erneutem Aufruf" do
    sign_in_as(@caretaker)
    post rollover_execute_path, params: {
      source_year_id: @source.id, target_year_id: @target.id,
      child_ids: [ @child_a.id ]
    }
    @child_a.reload

    assert_no_difference "Child.count" do
      post rollover_execute_path, params: {
        source_year_id: @target.id, target_year_id: @target.id,
        child_ids: [ @child_a.id ]
      }
    end
    assert_equal @target.id, @child_a.reload.kindergarten_year_id
  end

  test "F56 Execute ohne Zieljahr scheitert mit alert" do
    sign_in_as(@caretaker)
    post rollover_execute_path, params: { source_year_id: @source.id, child_ids: [ @child_a.id ] }
    assert_redirected_to rollover_path
    assert_match(/gültiges Zieljahr/, flash[:alert])
  end

  test "F56 Eltern haben keinen Zugriff auf execute" do
    sign_in_as(@parent)
    post rollover_execute_path, params: {
      source_year_id: @source.id, target_year_id: @target.id,
      child_ids: [ @child_a.id ]
    }
    assert_response :forbidden
  end
end
