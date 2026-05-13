require "test_helper"

class PollMultipleChoiceTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Multi-Wahl-Gruppe")
    @caretaker = User.create!(
      email: "multipoll_staff@mikiwa.at", password: "sicherespasswort1234", role: "caretaker"
    )
    @parent = User.create!(
      email: "multipoll_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000"
    )
    @child = Child.create!(
      first_name: "MultiKind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @poll = Poll.new(
      title: "Mehrfachauswahl-Test",
      poll_type: "multiple",
      status: "open",
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @poll.poll_options.build(label: "Option A")
    @poll.poll_options.build(label: "Option B")
    @poll.poll_options.build(label: "Option C")
    @poll.save!
    @opt_a, @opt_b, @opt_c = @poll.poll_options.to_a
  end

  teardown do
    Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id }).destroy_all
    @poll.poll_options.destroy_all
    @poll.destroy!
    ParentChild.where(user: @parent, child: @child).destroy_all
    @child.destroy!
    @parent.destroy!
    @caretaker.destroy!
    @group.destroy!
  end

  # TS-067-S01: Elternteil wählt Optionen A und C → beide gespeichert
  test "TS-067 Elternteil kann mehrere Optionen in Mehrfachauswahl wählen" do
    sign_in_as(@parent)

    post vote_poll_path(@poll), params: { option_ids: [ @opt_a.id, @opt_c.id ] }
    assert_response :redirect

    user_votes = Vote.joins(:poll_option).where(poll_options: { poll_id: @poll.id }, user: @parent)
    assert_equal 2, user_votes.count, "Genau 2 Votes müssen gespeichert sein"
    voted_option_ids = user_votes.pluck(:poll_option_id).to_set
    assert voted_option_ids.include?(@opt_a.id), "Option A muss gewählt sein"
    assert voted_option_ids.include?(@opt_c.id), "Option C muss gewählt sein"
    assert_not voted_option_ids.include?(@opt_b.id), "Option B darf nicht gewählt sein"
  end

  # Einfachauswahl blockiert zweite Wahl serverseitig
  test "TS-067 Einfachauswahl speichert nur eine Option auch wenn mehrere übermittelt" do
    single_poll = Poll.new(
      title: "Einfachauswahl-Test",
      poll_type: "single",
      status: "open",
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    single_poll.poll_options.build(label: "Eins")
    single_poll.poll_options.build(label: "Zwei")
    single_poll.save!
    opt1, opt2 = single_poll.poll_options.to_a

    sign_in_as(@parent)
    post vote_poll_path(single_poll), params: { option_ids: [ opt1.id, opt2.id ] }
    assert_response :redirect

    votes = Vote.joins(:poll_option).where(poll_options: { poll_id: single_poll.id }, user: @parent)
    assert_equal 1, votes.count, "Einfachauswahl darf nur 1 Vote speichern"

    votes.destroy_all
    single_poll.poll_options.destroy_all
    single_poll.destroy!
  end
end
