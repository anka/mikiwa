require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email" do
    user = User.new(email: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email)
  end

  # F35: Pflichtfelder für Eltern-Rolle
  test "F35 Parent ohne Telefon scheitert an Validation" do
    parent = User.new(
      email: "eltern@test.at",
      password: SecureRandom.hex(16),
      role: "parent",
      first_name: "Anna",
      last_name: "Huber",
      phone: ""
    )
    assert_not parent.valid?
    assert_includes parent.errors[:phone], "muss ausgefüllt werden"
  end

  test "F35 Parent ohne Vorname scheitert an Validation" do
    parent = User.new(
      email: "eltern2@test.at",
      password: SecureRandom.hex(16),
      role: "parent",
      first_name: "",
      last_name: "Huber",
      phone: "0664 123 456"
    )
    assert_not parent.valid?
    assert_includes parent.errors[:first_name], "muss ausgefüllt werden"
  end

  test "F35 Parent ohne Nachname scheitert an Validation" do
    parent = User.new(
      email: "eltern3@test.at",
      password: SecureRandom.hex(16),
      role: "parent",
      first_name: "Anna",
      last_name: "",
      phone: "0664 123 456"
    )
    assert_not parent.valid?
    assert_includes parent.errors[:last_name], "muss ausgefüllt werden"
  end

  test "F35 Caretaker ohne Telefon speichert erfolgreich" do
    caretaker = User.new(
      email: "betreuer_f35@test.at",
      password: SecureRandom.hex(16),
      role: "caretaker",
      first_name: "",
      last_name: "",
      phone: ""
    )
    assert caretaker.valid?
  end

  test "F35 Admin ohne Telefon speichert erfolgreich" do
    admin = User.new(
      email: "admin_f35@test.at",
      password: SecureRandom.hex(16),
      role: "admin",
      first_name: "",
      last_name: "",
      phone: ""
    )
    assert admin.valid?
  end

  test "F35 Parent mit allen Pflichtfeldern ist valide" do
    parent = User.new(
      email: "vollstaendig@test.at",
      password: SecureRandom.hex(16),
      role: "parent",
      first_name: "Maria",
      last_name: "Muster",
      phone: "0650 999 111"
    )
    assert parent.valid?
  end
end
