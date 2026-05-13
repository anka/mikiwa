require "test_helper"

class ChildTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Bären")
    @year = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @parent = User.create!(email: "parent_c@test.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @child = Child.new(
      first_name:        "Lena",
      last_name:         "Baum",
      date_of_birth:     Date.new(2021, 3, 15),
      group:             @group,
      kindergarten_year: @year,
      photo_consent:     true
    )
  end

  test "valid child can be saved" do
    assert @child.save
  end

  test "first_name is required" do
    @child.first_name = nil
    assert_not @child.save
    assert @child.errors[:first_name].any?
  end

  test "date_of_birth is required" do
    @child.date_of_birth = nil
    assert_not @child.save
    assert @child.errors[:date_of_birth].any?
  end

  test "photo_consent must be explicitly set" do
    @child.photo_consent = nil
    assert_not @child.save
    assert @child.errors[:photo_consent].any?
  end

  test "child is active by default" do
    @child.save!
    assert @child.active?
  end

  test "deactivate! sets active to false" do
    @child.save!
    @child.deactivate!
    assert_not @child.reload.active?
  end

  test "active scope includes only active children" do
    @child.save!
    inactive = Child.create!(
      first_name: "Max", last_name: "Wolf",
      date_of_birth: Date.new(2020, 5, 1),
      group: @group, kindergarten_year: @year,
      photo_consent: false, active: false
    )
    active_ids = Child.active.pluck(:id)
    assert_includes active_ids, @child.id
    assert_not_includes active_ids, inactive.id
  end

  test "display_name returns nickname when present" do
    @child.nickname = "Leni"
    assert_equal "Leni", @child.display_name
  end

  test "display_name returns first_name when no nickname" do
    assert_equal "Lena", @child.display_name
  end

  test "full_name returns first and last name" do
    @child.save!
    assert_equal "Lena Baum", @child.full_name
  end

  test "parent can be linked to child" do
    @child.save!
    ParentChild.create!(user: @parent, child: @child)
    assert_includes @child.reload.parents, @parent
    assert_includes @parent.reload.children, @child
  end

  test "transfer_to copies child to new year" do
    @child.save!
    ParentChild.create!(user: @parent, child: @child)
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27",
      start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31),
      active: false
    )
    new_child = @child.transfer_to(new_year)
    assert_equal new_year, new_child.kindergarten_year
    assert_includes new_child.parents, @parent
  end

  test "transfer_to copies emergency contacts to new year" do
    @child.save!
    EmergencyContact.create!(child: @child, name: "Oma", relationship: "Großmutter", phone: "+43 650 111", position: 1)
    EmergencyContact.create!(child: @child, name: "Papa", relationship: "Vater", phone: "+43 650 222", position: 2)
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27", start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31), active: false
    )
    new_child = @child.transfer_to(new_year)
    assert_equal 2, new_child.emergency_contacts.count
    assert_equal "Oma", new_child.emergency_contacts.first.name
  end

  test "transfer_to copies medical notes to new year" do
    @child.save!
    MedicalNote.create!(child: @child, note_type: "allergy", content: "Erdnussallergie")
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27", start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31), active: false
    )
    new_child = @child.transfer_to(new_year)
    assert_equal 1, new_child.medical_notes.count
    assert_equal "Erdnussallergie", new_child.medical_notes.first.content
  end

  test "transfer_to is idempotent" do
    @child.save!
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27",
      start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31),
      active: false
    )
    @child.transfer_to(new_year)
    assert_no_difference "Child.count" do
      @child.transfer_to(new_year)
    end
  end
end
