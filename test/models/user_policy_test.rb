require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @admin     = User.create!(email: "admin_up@mikiwa.at",     password: "sicherespasswort1234", role: "admin")
    @caretaker = User.create!(email: "caretaker_up@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_up@mikiwa.at",    password: SecureRandom.hex(20),   role: "parent")
    @other_parent = User.create!(email: "eltern2_up@mikiwa.at", password: SecureRandom.hex(20),  role: "parent")
    @other_caretaker = User.create!(email: "caretaker2_up@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
  end

  # F20 R-P0-001: Staff darf Eltern-Records bearbeiten
  test "Caretaker darf parent index/show/new/create/edit/update" do
    policy = UserPolicy.new(@caretaker, @parent)
    assert policy.index?
    assert policy.show?
    assert policy.new?
    assert policy.create?
    assert policy.edit?
    assert policy.update?
  end

  test "Admin darf parent index/show/new/create/edit/update" do
    policy = UserPolicy.new(@admin, @parent)
    assert policy.edit?
    assert policy.update?
    assert policy.create?
  end

  # F20 R-P0-001 Acceptance: Staff darf NICHT Admin/Staff-Records bearbeiten
  test "Caretaker darf NICHT anderen Caretaker editieren" do
    policy = UserPolicy.new(@caretaker, @other_caretaker)
    assert_not policy.edit?
    assert_not policy.update?
  end

  test "Caretaker darf NICHT Admin editieren" do
    policy = UserPolicy.new(@caretaker, @admin)
    assert_not policy.edit?
    assert_not policy.update?
  end

  # Eltern selbst dürfen nicht bearbeiten
  test "Eltern darf NICHT andere parent editieren" do
    policy = UserPolicy.new(@parent, @other_parent)
    assert_not policy.edit?
    assert_not policy.update?
    assert_not policy.index?
  end

  # Spec non-goal: Löschen bleibt Admin-only
  test "Caretaker darf NICHT destroy parent" do
    policy = UserPolicy.new(@caretaker, @parent)
    assert_not policy.destroy?
  end

  test "Admin darf destroy parent" do
    policy = UserPolicy.new(@admin, @parent)
    assert policy.destroy?
  end

  # F21: Show-Berechtigung
  test "F21 Eltern darf eigene Show-Seite (sich selbst)" do
    policy = UserPolicy.new(@parent, @parent)
    assert policy.show?
  end

  test "F21 Eltern darf NICHT andere Eltern-Show öffnen" do
    policy = UserPolicy.new(@parent, @other_parent)
    assert_not policy.show?
  end

  test "F21 Staff darf jede parent-Show öffnen" do
    assert UserPolicy.new(@caretaker, @parent).show?
    assert UserPolicy.new(@admin, @parent).show?
  end
end
