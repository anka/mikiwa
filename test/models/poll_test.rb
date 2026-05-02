require "test_helper"

class PollTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Abstimmungs-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_poll@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_poll@mikiwa.at", password: "sicherespasswort1234", role: "parent")

    @poll = Poll.new(
      title: "Ausflugsziel", poll_type: "single", group: @group,
      kindergarten_year: @year, created_by: @staff
    )
    @poll.poll_options.build(label: "Wald")
    @poll.poll_options.build(label: "Museum")
  end

  test "valid poll can be saved" do
    assert @poll.save, @poll.errors.full_messages.inspect
  end

  test "uses UUID primary key" do
    @poll.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @poll.id)
  end

  test "title is required" do
    @poll.title = nil
    assert_not @poll.valid?
    assert @poll.errors[:title].any?
  end

  test "poll_type must be single or multiple" do
    @poll.poll_type = "invalid"
    assert_not @poll.valid?
    assert @poll.errors[:poll_type].any?
  end

  test "at least one option required" do
    poll = Poll.new(title: "Leer", poll_type: "single", group: @group,
                    kindergarten_year: @year, created_by: @staff)
    assert_not poll.valid?
    assert poll.errors[:poll_options].any?
  end

  test "open? returns true when status open and no deadline" do
    @poll.save!
    assert @poll.open?
  end

  test "open? returns false when status closed" do
    @poll.save!
    @poll.update!(status: "closed")
    assert_not @poll.open?
  end

  test "open? returns false when deadline is past" do
    @poll.save!
    @poll.update!(deadline: 1.hour.ago)
    assert_not @poll.open?
  end

  test "open? returns true when deadline is in future" do
    @poll.save!
    @poll.update!(deadline: 1.hour.from_now)
    assert @poll.open?
  end

  test "close! sets status to closed" do
    @poll.save!
    @poll.close!
    assert_equal "closed", @poll.reload.status
  end

  test "vote! stores a vote for single-choice poll" do
    @poll.save!
    option = @poll.poll_options.order(:created_at).first
    assert_difference "Vote.count", 1 do
      @poll.vote!(user: @parent, option_ids: [ option.id ])
    end
  end

  test "vote! replaces existing vote for single-choice poll" do
    @poll.save!
    opt_a = @poll.poll_options.order(:created_at).first
    opt_b = @poll.poll_options.order(:created_at).last
    @poll.vote!(user: @parent, option_ids: [ opt_a.id ])
    assert_no_difference "Vote.count" do
      @poll.vote!(user: @parent, option_ids: [ opt_b.id ])
    end
    assert Vote.exists?(poll_option: opt_b, user: @parent)
    assert_not Vote.exists?(poll_option: opt_a, user: @parent)
  end

  test "vote! raises ClosedError when poll is closed" do
    @poll.save!
    @poll.close!
    option = @poll.poll_options.order(:created_at).first
    assert_raises(Poll::ClosedError) do
      @poll.vote!(user: @parent, option_ids: [ option.id ])
    end
  end

  test "vote! stores multiple votes for multiple-choice poll" do
    @poll.poll_type = "multiple"
    @poll.save!
    opt_a = @poll.poll_options.order(:created_at).first
    opt_b = @poll.poll_options.order(:created_at).last
    assert_difference "Vote.count", 2 do
      @poll.vote!(user: @parent, option_ids: [ opt_a.id, opt_b.id ])
    end
  end

  test "votes_by_option returns hash keyed by option" do
    @poll.save!
    option = @poll.poll_options.order(:created_at).first
    @poll.vote!(user: @parent, option_ids: [ option.id ])
    result = @poll.votes_by_option
    assert_includes result.keys, option
    assert_includes result[option], @parent
  end

  test "ordered scope sorts by created_at desc" do
    @poll.save!
    poll2 = Poll.new(title: "Zweite", poll_type: "single", group: @group,
                     kindergarten_year: @year, created_by: @staff)
    poll2.poll_options.build(label: "Option A")
    poll2.save!
    assert_equal poll2.id, Poll.ordered.first.id
  end
end
