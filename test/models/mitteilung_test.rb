require "test_helper"

class MitteilungTest < ActiveSupport::TestCase
  setup do
    @group_a   = Group.create!(name: "Mitteil-Bären")
    @group_b   = Group.create!(name: "Mitteil-Löwen")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "betreuer_mitt@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent_a  = User.create!(email: "eltern_mitt_a@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @parent_b  = User.create!(email: "eltern_mitt_b@mikiwa.at", password: SecureRandom.hex(20), role: "parent")

    @child_a = Child.create!(
      first_name: "Tim", last_name: "Schwarz",
      date_of_birth: Date.new(2021, 2, 1),
      group: @group_a, kindergarten_year: @year, photo_consent: true
    )
    @child_b = Child.create!(
      first_name: "Eva", last_name: "Braun",
      date_of_birth: Date.new(2021, 4, 1),
      group: @group_b, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent_a, child: @child_a)
    ParentChild.create!(user: @parent_b, child: @child_b)
  end

  test "valid Mitteilung can be saved" do
    msg = Mitteilung.new(
      title: "Ausflug am Montag",
      body: "Bitte Gummistiefel mitbringen.",
      sent_by: @caretaker
    )
    msg.mitteilung_groups.build(group: @group_a)
    assert msg.save, msg.errors.full_messages.inspect
  end

  test "uses UUID primary key" do
    msg = Mitteilung.new(title: "T", body: "B", sent_by: @caretaker)
    msg.mitteilung_groups.build(group: @group_a)
    msg.save!
    assert_match(/\A[0-9a-f-]{36}\z/, msg.id)
  end

  test "title is required" do
    msg = Mitteilung.new(body: "B", sent_by: @caretaker)
    msg.mitteilung_groups.build(group: @group_a)
    assert_not msg.valid?
    assert msg.errors[:title].any?
  end

  test "at least one group required" do
    msg = Mitteilung.new(title: "T", body: "B", sent_by: @caretaker)
    assert_not msg.valid?
    assert msg.errors[:mitteilung_groups].any?
  end

  test "deliver! creates inbox entries for parents in group" do
    msg = Mitteilung.new(title: "T", body: "B", sent_by: @caretaker)
    msg.mitteilung_groups.build(group: @group_a)
    msg.save!
    assert_difference "Posteingang.count", 1 do
      msg.deliver!
    end
    entry = Posteingang.last
    assert_equal @parent_a, entry.user
    assert_equal msg, entry.mitteilung
    assert_nil entry.read_at
  end

  test "deliver! does not duplicate entries for same user" do
    msg = Mitteilung.new(title: "T", body: "B", sent_by: @caretaker)
    msg.mitteilung_groups.build(group: @group_a)
    msg.save!
    msg.deliver!
    assert_no_difference "Posteingang.count" do
      msg.deliver!
    end
  end

  test "deliver! only sends to parents of relevant groups" do
    msg = Mitteilung.new(title: "T", body: "B", sent_by: @caretaker)
    msg.mitteilung_groups.build(group: @group_a)
    msg.save!
    msg.deliver!
    recipients = Posteingang.where(mitteilung: msg).map(&:user)
    assert_includes recipients, @parent_a
    assert_not_includes recipients, @parent_b
  end

  test "marking as read sets read_at" do
    msg = Mitteilung.new(title: "T", body: "B", sent_by: @caretaker)
    msg.mitteilung_groups.build(group: @group_a)
    msg.save!
    msg.deliver!
    entry = Posteingang.find_by(user: @parent_a, mitteilung: msg)
    entry.mark_as_read!
    assert entry.reload.read?
    assert entry.read_at.present?
  end
end
