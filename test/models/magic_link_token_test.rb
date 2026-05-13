require "test_helper"

class MagicLinkTokenTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "magic_token_test@test.de",
      password: "sicherespasswort1234",
      role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000"
    )
  end

  teardown do
    @user.destroy!
  end

  # TS-004-S01: Token nach Verwendung ungültig
  test "verwendeter Token ist danach ungültig" do
    token = @user.generate_token_for(:magic_link)
    assert_not_nil User.find_by_token_for(:magic_link, token), "Token sollte vor Verwendung gültig sein"

    @user.invalidate_magic_link_token!

    assert_nil User.find_by_token_for(:magic_link, token), "Token sollte nach Invalidierung ungültig sein"
  end

  # TS-004-S02: Token nach >30 Minuten abgelaufen
  test "abgelaufener Token nach 31 Minuten ist ungültig" do
    token = nil

    travel_to 31.minutes.ago do
      token = @user.generate_token_for(:magic_link)
    end

    assert_nil User.find_by_token_for(:magic_link, token), "Token sollte nach 31 Minuten abgelaufen sein"
  end

  test "frischer Token ist gültig" do
    token = @user.generate_token_for(:magic_link)
    assert_equal @user, User.find_by_token_for(:magic_link, token)
  end

  test "Token kurz vor Ablauf (29 Minuten) ist noch gültig" do
    token = nil

    travel_to 29.minutes.ago do
      token = @user.generate_token_for(:magic_link)
    end

    assert_not_nil User.find_by_token_for(:magic_link, token), "Token sollte nach 29 Minuten noch gültig sein"
  end
end
