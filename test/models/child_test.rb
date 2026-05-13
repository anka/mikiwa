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

  test "BF-007 transfer_to wechselt kindergarten_year ohne neuen Child anzulegen" do
    @child.save!
    ParentChild.create!(user: @parent, child: @child)
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27",
      start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31),
      active: false
    )
    assert_no_difference "Child.count" do
      result = @child.transfer_to(new_year)
      assert_equal @child.id, result.id
    end
    @child.reload
    assert_equal new_year.id, @child.kindergarten_year_id
    assert_includes @child.parents, @parent
  end

  test "BF-007 transfer_to behält emergency_contacts am bestehenden Child" do
    @child.save!
    ec1 = EmergencyContact.create!(child: @child, name: "Oma", relationship: "Großmutter", phone: "+43 650 111", position: 1)
    ec2 = EmergencyContact.create!(child: @child, name: "Papa", relationship: "Vater", phone: "+43 650 222", position: 2)
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27", start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31), active: false
    )
    assert_no_difference "EmergencyContact.count" do
      @child.transfer_to(new_year)
    end
    @child.reload
    assert_equal [ ec1.id, ec2.id ].sort, @child.emergency_contacts.pluck(:id).sort
  end

  test "BF-007 transfer_to behält medical_notes am bestehenden Child" do
    @child.save!
    mn = MedicalNote.create!(child: @child, note_type: "allergy", content: "Erdnussallergie")
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27", start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31), active: false
    )
    assert_no_difference "MedicalNote.count" do
      @child.transfer_to(new_year)
    end
    @child.reload
    assert_equal [ mn.id ], @child.medical_notes.pluck(:id)
  end

  test "BF-007 transfer_to reaktiviert deaktiviertes Kind" do
    @child.active = false
    @child.save!
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27", start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31), active: false
    )
    @child.transfer_to(new_year)
    assert @child.reload.active?
  end

  test "age returns full years based on Date.current" do
    travel_to Date.new(2026, 5, 13) do
      @child.date_of_birth = Date.new(2021, 5, 13)
      @child.save!
      assert_equal 5, @child.age
    end
  end

  test "age does not increment when birthday is tomorrow" do
    travel_to Date.new(2026, 5, 13) do
      @child.date_of_birth = Date.new(2021, 5, 14)
      @child.save!
      assert_equal 4, @child.age
    end
  end

  test "age increments on day before birthday is past" do
    travel_to Date.new(2026, 5, 13) do
      @child.date_of_birth = Date.new(2021, 5, 12)
      @child.save!
      assert_equal 5, @child.age
    end
  end

  test "age handles leap-year birthdays gracefully" do
    travel_to Date.new(2026, 3, 1) do
      @child.date_of_birth = Date.new(2020, 2, 29)
      @child.save!
      assert_equal 6, @child.age
    end
  end

  test "BF-007 transfer_to ist idempotent bei gleichem Zieljahr" do
    @child.save!
    @child.transfer_to(@year)
    updated_at_before = @child.reload.updated_at
    assert_no_difference "Child.count" do
      @child.transfer_to(@year)
    end
    assert_equal updated_at_before, @child.reload.updated_at,
                 "Idempotenter Aufruf darf updated_at nicht ändern"
  end
end
