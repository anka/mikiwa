require "test_helper"

class AbstimmungTest < ActiveSupport::TestCase
  setup do
    @group    = Group.create!(name: "Abstimmung-Bären")
    @year     = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "betreuer_ab@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_ab@mikiwa.at",  password: SecureRandom.hex(20), role: "parent")

    @poll = Abstimmung.new(
      title: "Sommerfest-Datum",
      poll_type: "einfach",
      group: @group,
      kindergarten_year: @year,
      created_by: @caretaker
    )
    @poll.abstimmung_optionen.build(label: "22. Juni", position: 1)
    @poll.abstimmung_optionen.build(label: "29. Juni", position: 2)
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

  test "poll_type must be einfach or mehrfach" do
    @poll.poll_type = "invalid"
    assert_not @poll.valid?
  end

  test "at least one option required" do
    poll = Abstimmung.new(
      title: "Leer", poll_type: "einfach",
      group: @group, kindergarten_year: @year, created_by: @caretaker
    )
    assert_not poll.valid?
    assert poll.errors[:abstimmung_optionen].any?
  end

  test "defaults to offen status" do
    @poll.save!
    assert_equal "offen", @poll.status
  end

  test "open? returns true when offen and no deadline" do
    @poll.save!
    assert @poll.open?
  end

  test "open? returns false when deadline has passed" do
    @poll.deadline = 1.day.ago
    @poll.save!
    assert_not @poll.open?
  end

  test "open? returns true when deadline is in future" do
    @poll.deadline = 1.day.from_now
    @poll.save!
    assert @poll.open?
  end

  test "open? returns false when status is geschlossen" do
    @poll.save!
    @poll.close!
    assert_not @poll.open?
  end

  test "close! sets status to geschlossen" do
    @poll.save!
    @poll.close!
    assert_equal "geschlossen", @poll.reload.status
  end

  # --- Einfachauswahl ---
  test "einfachauswahl: Stimme ändern removes old vote" do
    @poll.save!
    option_a = @poll.abstimmung_optionen.first
    option_b = @poll.abstimmung_optionen.last

    Stimme.create!(abstimmung_option: option_a, user: @parent)
    assert_equal 1, @parent.stimmen.count

    @poll.vote!(user: @parent, option_ids: [option_b.id])

    assert_equal 1, @parent.stimmen.count
    assert_equal option_b, @parent.stimmen.first.abstimmung_option
  end

  test "einfachauswahl: only one vote per user enforced" do
    @poll.save!
    option_a = @poll.abstimmung_optionen.first
    option_b = @poll.abstimmung_optionen.last

    @poll.vote!(user: @parent, option_ids: [option_a.id, option_b.id])
    assert_equal 1, @parent.stimmen.count
  end

  # --- Mehrfachauswahl ---
  test "mehrfachauswahl: multiple votes allowed" do
    @poll.update!(poll_type: "mehrfach")
    @poll.save!
    option_a = @poll.abstimmung_optionen.first
    option_b = @poll.abstimmung_optionen.last

    @poll.vote!(user: @parent, option_ids: [option_a.id, option_b.id])
    assert_equal 2, @parent.stimmen.count
  end

  test "mehrfachauswahl: Stimmen ändern replaces all votes" do
    @poll.update!(poll_type: "mehrfach")
    @poll.save!
    option_a = @poll.abstimmung_optionen.first
    option_b = @poll.abstimmung_optionen.last

    @poll.vote!(user: @parent, option_ids: [option_a.id, option_b.id])
    @poll.vote!(user: @parent, option_ids: [option_b.id])

    assert_equal 1, @parent.stimmen.count
    assert_equal option_b, @parent.stimmen.first.abstimmung_option
  end

  # --- Stimmschluss ---
  test "vote! raises when deadline passed" do
    @poll.deadline = 1.day.ago
    @poll.save!
    option = @poll.abstimmung_optionen.first
    assert_raises(Abstimmung::ClosedError) do
      @poll.vote!(user: @parent, option_ids: [option.id])
    end
  end

  test "vote! raises when status is geschlossen" do
    @poll.save!
    @poll.close!
    option = @poll.abstimmung_optionen.first
    assert_raises(Abstimmung::ClosedError) do
      @poll.vote!(user: @parent, option_ids: [option.id])
    end
  end

  # --- Ergebnis ---
  test "votes_by_option returns hash of option => users" do
    @poll.save!
    option_a = @poll.abstimmung_optionen.first
    @poll.vote!(user: @parent, option_ids: [option_a.id])

    result = @poll.votes_by_option
    assert_includes result[option_a], @parent
  end
end
