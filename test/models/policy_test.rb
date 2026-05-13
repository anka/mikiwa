require "test_helper"

class PolicyTest < ActiveSupport::TestCase
  def admin_user
    @admin ||= User.create!(email: "admin@test.com", password: "sicherespasswort1234", role: "admin")
  end

  def caretaker_user
    @caretaker ||= User.create!(email: "betreuer@test.com", password: "sicherespasswort1234", role: "caretaker")
  end

  def parent_user
    @parent ||= User.create!(email: "eltern@test.com", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
  end

  test "ApplicationPolicy: Admin darf alles" do
    policy = ApplicationPolicy.new(admin_user, :anything)
    assert policy.admin?
    assert_not policy.parent?
  end

  test "ApplicationPolicy: Caretaker ist kein Admin" do
    policy = ApplicationPolicy.new(caretaker_user, :anything)
    assert_not policy.admin?
    assert policy.staff?
  end

  test "ApplicationPolicy: Elternteil ist kein Staff" do
    policy = ApplicationPolicy.new(parent_user, :anything)
    assert_not policy.staff?
    assert policy.parent?
  end

  test "ApplicationPolicy: unauthentifizierter Zugriff wirft PolicyNotAuthorizedError" do
    assert_raises(ApplicationPolicy::NotAuthorizedError) do
      ApplicationPolicy.new(nil, :anything).authorize!
    end
  end
end
