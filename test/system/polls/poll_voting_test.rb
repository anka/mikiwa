require "test_helper"

class PollVotingTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Poll-Gruppe")
    @caretaker = User.create!(email: "poll_caretaker@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "poll_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent", first_name: "Maria", last_name: "Muster")
    @child = Child.create!(
      first_name: "Poll-Kind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @poll = Poll.new(
      title: "Ausflugsziel", poll_type: "single", status: "open",
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
    @option_a = @poll.poll_options.build(label: "Zoo")
    @option_b = @poll.poll_options.build(label: "Museum")
    @poll.save!
  end

  teardown do
    Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id }).destroy_all
    @poll.poll_options.destroy_all
    @poll.destroy!
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-043-S01: Stimme abgeben
  test "TS-043 Elternteil gibt Stimme ab und Ergebnis zeigt Namen" do
    sign_in_as(@parent)

    post vote_poll_path(@poll), params: { option_ids: [ @option_a.id ] }
    assert_response :redirect

    follow_redirect!
    assert_match @parent.full_name, response.body
  end

  # TS-043-S02: Stimme ändern
  test "TS-043 Elternteil ändert Stimme von Option A zu Option B" do
    @poll.vote!(user: @parent, option_ids: [ @option_a.id ])

    sign_in_as(@parent)

    post vote_poll_path(@poll), params: { option_ids: [ @option_b.id ] }
    assert_response :redirect

    assert_equal 1, Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id }, user: @parent).count
    assert Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id, id: @option_b.id }, user: @parent).exists?
    assert_not Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id, id: @option_a.id }, user: @parent).exists?
  end

  # TS-043-S03: Stimmschluss verhindert Abstimmung
  test "TS-043 Abstimmung nach Stimmschluss nicht mehr möglich" do
    @poll.update!(status: "closed")
    sign_in_as(@parent)

    post vote_poll_path(@poll), params: { option_ids: [ @option_a.id ] }
    assert_response :unprocessable_entity
  end
end
