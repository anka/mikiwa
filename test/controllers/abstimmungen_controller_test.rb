require "test_helper"

class AbstimmungenControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_abc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_abc@mikiwa.at",   password: SecureRandom.hex(20), role: "parent")
    @parent2   = User.create!(email: "eltern2_abc@mikiwa.at",  password: SecureRandom.hex(20), role: "parent")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Abstimmung-Bären2")
    @group_loewen = Group.create!(name: "Abstimmung-Löwen2")

    @child = Child.create!(
      first_name: "Lena", last_name: "Huber",
      date_of_birth: Date.new(2021, 5, 1),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @poll = Abstimmung.new(
      title: "Ausflug-Termin",
      poll_type: "einfach",
      group: @group_baeren,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @poll.abstimmung_optionen.build(label: "15. Juli", position: 1)
    @poll.abstimmung_optionen.build(label: "22. Juli", position: 2)
    @poll.save!
    @option_a = @poll.abstimmung_optionen.order(:position).first
    @option_b = @poll.abstimmung_optionen.order(:position).last

    poll_loewen = Abstimmung.new(
      title: "Löwen-Abstimmung",
      poll_type: "einfach",
      group: @group_loewen,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    poll_loewen.abstimmung_optionen.build(label: "Ja", position: 1)
    poll_loewen.save!
  end

  # --- Auth guard ---
  test "unauthenticated user is redirected" do
    get abstimmungen_path
    assert_redirected_to new_session_path
  end

  # --- Index ---
  test "caretaker sees all polls" do
    sign_in_as(@caretaker)
    get abstimmungen_path
    assert_response :success
    assert_match "Ausflug-Termin", response.body
    assert_match "Löwen-Abstimmung", response.body
  end

  test "parent sees only polls for own group" do
    sign_in_as(@parent)
    get abstimmungen_path
    assert_response :success
    assert_match "Ausflug-Termin", response.body
    assert_no_match "Löwen-Abstimmung", response.body
  end

  # --- Show (namentliches Ergebnis) ---
  test "authenticated user can view poll" do
    sign_in_as(@parent)
    get abstimmung_path(@poll)
    assert_response :success
    assert_match "Ausflug-Termin", response.body
  end

  test "parent from other group cannot view poll (403)" do
    sign_in_as(@parent2)
    get abstimmung_path(@poll)
    assert_response :forbidden
  end

  test "show displays voter names" do
    Stimme.create!(abstimmung_option: @option_a, user: @parent)
    sign_in_as(@caretaker)
    get abstimmung_path(@poll)
    assert_response :success
    assert_match @parent.full_name.presence || @parent.email, response.body
  end

  # --- Create ---
  test "caretaker can create poll with options" do
    sign_in_as(@caretaker)
    assert_difference "Abstimmung.count", 1 do
      post abstimmungen_path, params: {
        abstimmung: {
          title: "Neue Abstimmung",
          poll_type: "einfach",
          group_id: @group_baeren.id,
          kindergarten_year_id: @year.id,
          abstimmung_optionen_attributes: [
            { label: "Option A", position: 1 },
            { label: "Option B", position: 2 }
          ]
        }
      }
    end
    assert_redirected_to abstimmung_path(Abstimmung.order(:created_at).last)
  end

  test "parent cannot create poll (403)" do
    sign_in_as(@parent)
    post abstimmungen_path, params: {
      abstimmung: { title: "X", poll_type: "einfach", group_id: @group_baeren.id, kindergarten_year_id: @year.id }
    }
    assert_response :forbidden
  end

  # --- Vote ---
  test "parent can vote on open poll" do
    sign_in_as(@parent)
    assert_difference "Stimme.count", 1 do
      post vote_abstimmung_path(@poll), params: { option_ids: [@option_a.id] }
    end
    assert_redirected_to abstimmung_path(@poll)
  end

  test "einfachauswahl: second vote replaces first" do
    Stimme.create!(abstimmung_option: @option_a, user: @parent)
    sign_in_as(@parent)
    assert_no_difference "Stimme.count" do
      post vote_abstimmung_path(@poll), params: { option_ids: [@option_b.id] }
    end
    assert_redirected_to abstimmung_path(@poll)
    assert_equal @option_b, @parent.stimmen.reload.first.abstimmung_option
  end

  test "parent cannot vote after deadline" do
    @poll.update!(deadline: 1.day.ago)
    sign_in_as(@parent)
    assert_no_difference "Stimme.count" do
      post vote_abstimmung_path(@poll), params: { option_ids: [@option_a.id] }
    end
    assert_response :unprocessable_entity
  end

  test "parent from other group cannot vote (403)" do
    sign_in_as(@parent2)
    post vote_abstimmung_path(@poll), params: { option_ids: [@option_a.id] }
    assert_response :forbidden
  end

  # --- Close ---
  test "caretaker can close poll" do
    sign_in_as(@caretaker)
    patch close_abstimmung_path(@poll)
    assert_redirected_to abstimmung_path(@poll)
    assert_equal "geschlossen", @poll.reload.status
  end

  test "parent cannot close poll (403)" do
    sign_in_as(@parent)
    patch close_abstimmung_path(@poll)
    assert_response :forbidden
  end

  # --- CSV export ---
  test "caretaker can download CSV export" do
    Stimme.create!(abstimmung_option: @option_a, user: @parent)
    sign_in_as(@caretaker)
    get export_abstimmung_path(@poll, format: :csv)
    assert_response :success
    assert_match "text/csv", response.content_type
    assert_match @parent.full_name.presence || @parent.email, response.body
    assert_match "15. Juli", response.body
  end

  test "parent cannot download CSV (403)" do
    sign_in_as(@parent)
    get export_abstimmung_path(@poll, format: :csv)
    assert_response :forbidden
  end
end
