require "test_helper"

class AttendanceListTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Listen-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @caretaker = User.create!(email: "betreuer_al@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_al@mikiwa.at",  password: SecureRandom.hex(20),   role: "parent")
    @child     = Child.create!(
      first_name: "Mia", last_name: "Lang",
      date_of_birth: Date.new(2021, 6, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @list = AttendanceList.new(
      title: "Waldtag-Anmeldung",
      mode: "general",
      kindergarten_year: @year,
      group: @group,
      created_by: @caretaker
    )
  end

  test "valid list can be saved" do
    assert @list.save, @list.errors.full_messages.inspect
  end

  test "title is required" do
    @list.title = nil
    assert_not @list.save
    assert @list.errors[:title].any?
  end

  test "mode must be general or per_date" do
    @list.mode = "invalid"
    assert_not @list.save
    assert @list.errors[:mode].any?
  end

  test "list uses UUID primary key" do
    @list.save!
    assert_match(/\A[0-9a-f-]{36}\z/, @list.id)
  end

  test "past deadline prevents new entries" do
    @list.deadline = 2.days.ago
    @list.save!
    assert @list.deadline_passed?
  end

  test "future deadline allows entries" do
    @list.deadline = 2.days.from_now
    @list.save!
    assert_not @list.deadline_passed?
  end

  test "no deadline always allows entries" do
    @list.deadline = nil
    @list.save!
    assert_not @list.deadline_passed?
  end

  test "entry can be added for child" do
    @list.save!
    entry = @list.attendance_entries.create!(child: @child, user: @parent)
    assert entry.persisted?
    assert_equal @child, entry.child
  end

  test "child can only be entered once per list" do
    @list.save!
    @list.attendance_entries.create!(child: @child, user: @parent)
    entry2 = @list.attendance_entries.build(child: @child, user: @parent)
    assert_not entry2.save
    assert entry2.errors[:child_id].any?
  end

  test "entry can be removed while deadline not passed" do
    @list.deadline = 2.days.from_now
    @list.save!
    entry = @list.attendance_entries.create!(child: @child, user: @parent)
    assert entry.destroy
    assert_equal 0, @list.attendance_entries.count
  end
end
