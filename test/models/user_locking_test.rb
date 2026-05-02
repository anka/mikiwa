require "test_helper"

class UserLockingTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "betreuer@test.at",
      password: "sicherespasswort1234",
      role: "caretaker",
      first_name: "Maria",
      last_name: "Muster"
    )
  end

  test "User ist standardmäßig nicht gesperrt" do
    assert_not @user.locked?
  end

  test "lock! sperrt einen Account und invalidiert Sessions" do
    @user.sessions.create!
    assert_equal 1, @user.sessions.count

    @user.lock!

    assert @user.reload.locked?
    assert_equal 0, @user.sessions.count
  end

  test "unlock! entsperrt einen Account" do
    @user.lock!
    assert @user.locked?

    @user.unlock!
    assert_not @user.reload.locked?
  end

  test "full_name gibt Vor- und Nachname zurück" do
    assert_equal "Maria Muster", @user.full_name
  end

  test "full_name ohne Nachnamen gibt nur Vornamen zurück" do
    user = User.create!(email: "nur@vorname.at", password: "sicherespasswort1234", first_name: "Klaus")
    assert_equal "Klaus", user.full_name
  end
end
