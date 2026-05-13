require "test_helper"

class PollsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "Poll-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_pc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_pc@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child  = Child.create!(
      first_name: "Emil", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @poll = Poll.new(
      title: "Ausflug", poll_type: "single", group: @group,
      kindergarten_year: @year, created_by: @staff
    )
    @poll.poll_options.build(label: "Wald")
    @poll.poll_options.build(label: "Museum")
    @poll.save!
  end

  # --- index ---

  test "staff can access polls list" do
    sign_in_as(@staff)
    get polls_path
    assert_response :success
  end

  test "parent can access polls list" do
    sign_in_as(@parent)
    get polls_path
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    get polls_path
    assert_response :redirect
  end

  # --- show ---

  test "staff can view poll" do
    sign_in_as(@staff)
    get poll_path(@poll)
    assert_response :success
  end

  test "parent in group can view poll" do
    sign_in_as(@parent)
    get poll_path(@poll)
    assert_response :success
  end

  # --- new / create ---

  test "staff can open new poll form" do
    sign_in_as(@staff)
    get new_poll_path
    assert_response :success
  end

  test "parent cannot open new poll form" do
    sign_in_as(@parent)
    get new_poll_path
    assert_response :forbidden
  end

  test "staff can create poll" do
    sign_in_as(@staff)
    assert_difference "Poll.count", 1 do
      post polls_path, params: {
        poll: {
          title: "Neue Abstimmung", poll_type: "single",
          group_id: @group.id, kindergarten_year_id: @year.id,
          poll_options_attributes: { "0" => { label: "Option A" }, "1" => { label: "Option B" } }
        }
      }
    end
    assert_redirected_to poll_path(Poll.order(:created_at).last)
  end

  test "parent cannot create poll" do
    sign_in_as(@parent)
    assert_no_difference "Poll.count" do
      post polls_path, params: {
        poll: {
          title: "Versuch", poll_type: "single",
          group_id: @group.id, kindergarten_year_id: @year.id,
          poll_options_attributes: { "0" => { label: "A" } }
        }
      }
    end
    assert_response :forbidden
  end

  test "create renders new on validation error" do
    sign_in_as(@staff)
    assert_no_difference "Poll.count" do
      post polls_path, params: {
        poll: {
          title: "", poll_type: "single",
          group_id: @group.id, kindergarten_year_id: @year.id,
          poll_options_attributes: { "0" => { label: "A" } }
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- vote ---

  test "parent can vote on open poll" do
    sign_in_as(@parent)
    option = @poll.poll_options.order(:created_at).first
    assert_difference "Vote.count", 1 do
      post vote_poll_path(@poll), params: { option_ids: [ option.id ] }
    end
    assert_redirected_to poll_path(@poll)
  end

  test "staff cannot vote (not parent)" do
    sign_in_as(@staff)
    option = @poll.poll_options.order(:created_at).first
    assert_no_difference "Vote.count" do
      post vote_poll_path(@poll), params: { option_ids: [ option.id ] }
    end
    assert_response :forbidden
  end

  test "vote on closed poll returns unprocessable_entity" do
    @poll.close!
    sign_in_as(@parent)
    option = @poll.poll_options.order(:created_at).first
    post vote_poll_path(@poll), params: { option_ids: [ option.id ] }
    assert_response :unprocessable_entity
  end

  # --- close ---

  test "staff can close poll" do
    sign_in_as(@staff)
    patch close_poll_path(@poll)
    assert_equal "closed", @poll.reload.status
    assert_redirected_to poll_path(@poll)
  end

  test "parent cannot close poll" do
    sign_in_as(@parent)
    patch close_poll_path(@poll)
    assert_response :forbidden
  end

  # --- export ---

  # TS-044-S01: Betreuer exportiert Abstimmungsergebnis als CSV mit allen Stimmen
  test "TS-044 CSV-Export enthält alle 3 Stimmen" do
    parent2 = User.create!(email: "poll_p2@mikiwa.at", password: SecureRandom.hex(20), role: "parent", first_name: "Anna", last_name: "Zwei", phone: "0664 000 002")
    parent3 = User.create!(email: "poll_p3@mikiwa.at", password: SecureRandom.hex(20), role: "parent", first_name: "Ben",  last_name: "Drei", phone: "0664 000 003")
    option = @poll.poll_options.order(:created_at).first

    @poll.vote!(user: @parent, option_ids: [ option.id ])
    @poll.vote!(user: parent2, option_ids: [ option.id ])
    @poll.vote!(user: parent3, option_ids: [ option.id ])

    sign_in_as(@staff)
    get export_poll_path(@poll, format: :csv)

    assert_response :success
    assert_match "text/csv", response.content_type

    data_lines = response.body.lines.reject { |l| l.strip.empty? }
    assert data_lines.size >= 4, "Header + 3 Datenzeilen erwartet, war #{data_lines.size}"
  ensure
    Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id }).destroy_all
    [ parent2, parent3 ].compact.each(&:destroy!)
  end

  test "staff can export CSV" do
    sign_in_as(@staff)
    get export_poll_path(@poll, format: :csv)
    assert_response :success
    assert_match "text/csv", response.content_type
  end

  test "parent cannot export CSV" do
    sign_in_as(@parent)
    get export_poll_path(@poll, format: :csv)
    assert_response :forbidden
  end

  # --- destroy ---

  test "staff can delete poll" do
    sign_in_as(@staff)
    assert_difference "Poll.count", -1 do
      delete poll_path(@poll)
    end
    assert_redirected_to polls_path
  end

  test "parent cannot delete poll" do
    sign_in_as(@parent)
    assert_no_difference "Poll.count" do
      delete poll_path(@poll)
    end
    assert_response :forbidden
  end
end
