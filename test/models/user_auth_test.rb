require "test_helper"

class UserAuthTest < ActiveSupport::TestCase
  test "Passwort kürzer als 16 Zeichen wird abgelehnt" do
    user = User.new(email: "test@example.com", password: "kurzpasswort12")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "Passwort mit 16 Zeichen ist valide" do
    user = User.new(email: "test@example.com", password: "sicherespasswort")
    assert user.valid?
  end

  test "Passwort kürzer als 16 Zeichen wird beim Update abgelehnt" do
    user = User.create!(email: "test2@example.com", password: "sicherespasswort1234")
    assert_not user.update(password: "kurz")
    assert user.errors[:password].any?
  end

  test "User hat eine Rolle" do
    user = User.create!(email: "role-test@example.com", password: "sicherespasswort1234")
    assert_not_nil user.role
  end

  test "Standard-Rolle ist caretaker" do
    user = User.create!(email: "default-role@example.com", password: "sicherespasswort1234")
    assert_equal "caretaker", user.role
  end

  test "Eltern können Magic-Link-Token generieren" do
    user = User.create!(email: "parent@example.com", password: SecureRandom.hex(20), role: "parent")
    token = user.generate_token_for(:magic_link)
    assert_not_nil token
    assert_not_empty token
  end

  test "Magic-Link-Token ist Single-Use: nach Verbrauch ungültig" do
    user = User.create!(email: "parent2@example.com", password: SecureRandom.hex(20), role: "parent")
    token = user.generate_token_for(:magic_link)
    found = User.find_by_token_for(:magic_link, token)
    assert_equal user, found

    # Token nach Verbrauch ungültig machen
    user.update_column(:magic_link_token_version, (user.magic_link_token_version || 0) + 1)
    found_again = User.find_by_token_for(:magic_link, token)
    assert_nil found_again
  end
end
