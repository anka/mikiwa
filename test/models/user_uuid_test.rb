require "test_helper"

class UserUuidTest < ActiveSupport::TestCase
  test "User hat UUID als Primärschlüssel" do
    user = User.create!(email: "uuid-test@example.com", password: "sicherespasswort1234")
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, user.id)
  end
end
