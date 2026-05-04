require "test_helper"

class ChildPolicyTest < ActiveSupport::TestCase
  setup do
    @admin     = User.create!(email: "admin_cp@mikiwa.at",     password: "sicherespasswort1234", role: "admin")
    @caretaker = User.create!(email: "caretaker_cp@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_cp@mikiwa.at",    password: SecureRandom.hex(20),   role: "parent")
    @group     = Group.create!(name: "Bären")
    @year      = KindergartenYear.create!(label: "KGJ 2025/26",
                                          start_date: Date.new(2025, 9, 1),
                                          end_date:   Date.new(2026, 7, 31),
                                          active: true)
    @child     = Child.create!(first_name: "Lina", last_name: "Wagner",
                               date_of_birth: Date.new(2021, 3, 1),
                               group: @group, kindergarten_year: @year,
                               photo_consent: true)
  end

  test "Admin darf manage_parents" do
    assert ChildPolicy.new(@admin, @child).manage_parents?
  end

  test "Caretaker darf manage_parents" do
    assert ChildPolicy.new(@caretaker, @child).manage_parents?
  end

  test "Eltern darf NICHT manage_parents" do
    assert_not ChildPolicy.new(@parent, @child).manage_parents?
  end

  test "Eltern darf show wenn Kind verknüpft ist" do
    ParentChild.create!(user: @parent, child: @child)
    assert ChildPolicy.new(@parent, @child).show?
  end

  test "Eltern darf show NICHT wenn Kind nicht verknüpft ist" do
    assert_not ChildPolicy.new(@parent, @child).show?
  end

  test "manage_parents? maps to attach_parent? and detach_parent?" do
    policy = ChildPolicy.new(@caretaker, @child)
    assert policy.attach_parent?
    assert policy.detach_parent?
  end
end
