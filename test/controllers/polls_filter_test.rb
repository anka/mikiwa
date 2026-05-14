require "test_helper"

class PollsFilterTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "f70_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @year = KindergartenYear.create!(
      label: "F70-KGJ", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_a = Group.create!(name: "F70-Gruppe-A")
    @group_b = Group.create!(name: "F70-Gruppe-B")

    @open_poll = build_poll!("Offene Frage", @group_a, poll_type: "single",
                              status: "open", deadline: 7.days.from_now)
    @deadline_poll = build_poll!("Stimmschluss vorbei", @group_a, poll_type: "single",
                                  status: "open", deadline: 1.day.ago)
    @closed_poll = build_poll!("Geschlossene Frage", @group_b, poll_type: "multiple",
                                status: "closed", deadline: nil)
  end

  test "F70 mw-filters Markup vorhanden" do
    sign_in_as(@caretaker)
    get polls_path
    assert_response :success
    assert_select "form.mw-filters"
    assert_select ".mw-filters__search"
    assert_select ".mw-filters__search-icon"
    assert_select "input[name='q'].mw-filters__search-input"
    assert_select "select[name='group_id'].mw-filters__select"
    assert_select "select[name='status'].mw-filters__select"
    assert_select "select[name='poll_type'].mw-filters__select"
  end

  test "F70 Titel-Suche filtert Polls" do
    sign_in_as(@caretaker)
    get polls_path(q: "Offene")
    assert_response :success
    assert_match "Offene Frage", response.body
    assert_no_match "Stimmschluss vorbei", response.body
    assert_no_match "Geschlossene Frage", response.body
  end

  test "F70 Status open zeigt nur offene aktive Polls" do
    sign_in_as(@caretaker)
    get polls_path(status: "open")
    assert_response :success
    assert_match "Offene Frage", response.body
    assert_no_match "Stimmschluss vorbei", response.body
    assert_no_match "Geschlossene Frage", response.body
  end

  test "F70 Status deadline_passed zeigt nur Stimmschluss-Polls" do
    sign_in_as(@caretaker)
    get polls_path(status: "deadline_passed")
    assert_response :success
    assert_match "Stimmschluss vorbei", response.body
    assert_no_match "Offene Frage", response.body
  end

  test "F70 Status closed zeigt nur geschlossene Polls" do
    sign_in_as(@caretaker)
    get polls_path(status: "closed")
    assert_response :success
    assert_match "Geschlossene Frage", response.body
    assert_no_match "Offene Frage", response.body
  end

  test "F70 Poll-Typ-Filter funktioniert" do
    sign_in_as(@caretaker)
    get polls_path(poll_type: "multiple")
    assert_response :success
    assert_match "Geschlossene Frage", response.body
    assert_no_match "Offene Frage", response.body
  end

  test "F70 Gruppe-Filter funktioniert" do
    sign_in_as(@caretaker)
    get polls_path(group_id: @group_b.id)
    assert_response :success
    assert_match "Geschlossene Frage", response.body
    assert_no_match "Offene Frage", response.body
  end

  test "F70 Reset-Link Badge zaehlt aktive Filter (3 Filter → '3')" do
    sign_in_as(@caretaker)
    get polls_path(q: "Frage", status: "open", poll_type: "single")
    assert_response :success
    assert_select ".mw-filters__reset"
    assert_select ".mw-filters__reset-count", text: "3"
  end

  test "F70 Reset-Link verschwindet ohne aktive Filter" do
    sign_in_as(@caretaker)
    get polls_path
    assert_response :success
    assert_select ".mw-filters__reset", count: 0
  end

  private

  def build_poll!(title, group, poll_type:, status:, deadline:)
    p = Poll.new(title: title, group: group, kindergarten_year: @year,
                 created_by: @caretaker, poll_type: poll_type, status: status,
                 deadline: deadline)
    p.poll_options.build(label: "Ja", position: 0)
    p.poll_options.build(label: "Nein", position: 1)
    p.save!
    p
  end
end
