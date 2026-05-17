require "test_helper"
require "stringio"

class CreateAdminServiceTest < ActiveSupport::TestCase
  setup do
    @original_email    = ENV["ADMIN_EMAIL"]
    @original_password = ENV["ADMIN_PASSWORD"]
    ENV.delete("ADMIN_EMAIL")
    ENV.delete("ADMIN_PASSWORD")
    @logger = StringIO.new
  end

  teardown do
    ENV["ADMIN_EMAIL"]    = @original_email
    ENV["ADMIN_PASSWORD"] = @original_password
  end

  test "überspringt mit Warnung, wenn ENV-Vars fehlen" do
    assert_no_difference "User.count" do
      result = CreateAdminService.call(logger: @logger)
      assert result.skipped?
      assert_nil result.user
    end
    assert_match(/übersprungen/, @logger.string)
  end

  test "überspringt, wenn nur Passwort gesetzt ist" do
    ENV["ADMIN_PASSWORD"] = "sicherespasswort1234567"
    assert_no_difference "User.count" do
      result = CreateAdminService.call(logger: @logger)
      assert result.skipped?
    end
  end

  test "überspringt, wenn ADMIN_EMAIL leer ist" do
    ENV["ADMIN_EMAIL"]    = "   "
    ENV["ADMIN_PASSWORD"] = "sicherespasswort1234567"
    assert_no_difference "User.count" do
      result = CreateAdminService.call(logger: @logger)
      assert result.skipped?
    end
  end

  test "legt neuen Admin an, wenn ENV-Vars gesetzt sind" do
    ENV["ADMIN_EMAIL"]    = "neuer-admin@mikiwa.at"
    ENV["ADMIN_PASSWORD"] = "sicherespasswort1234567"

    assert_difference "User.count", 1 do
      result = CreateAdminService.call(logger: @logger)
      assert result.created?
      assert_equal "neuer-admin@mikiwa.at", result.user.email
      assert_equal "admin", result.user.role
    end
  end

  test "lässt bestehenden Admin unverändert" do
    existing = User.create!(
      email:      "admin-da@mikiwa.at",
      password:   "altespasswort1234567",
      role:       "admin",
      first_name: "Bereits",
      last_name:  "Da"
    )
    ENV["ADMIN_EMAIL"]    = existing.email
    ENV["ADMIN_PASSWORD"] = "anderespasswort1234567"

    assert_no_difference "User.count" do
      result = CreateAdminService.call(logger: @logger)
      assert result.existing?
      assert_equal existing.id, result.user.id
    end

    assert existing.reload.authenticate("altespasswort1234567"),
           "Passwort darf nicht überschrieben werden"
  end

  test "überspringt bei ungültigem Passwort (Validation-Fehler)" do
    ENV["ADMIN_EMAIL"]    = "weiterer-admin@mikiwa.at"
    ENV["ADMIN_PASSWORD"] = "zukurz"

    assert_no_difference "User.count" do
      result = CreateAdminService.call(logger: @logger)
      assert result.skipped?
      assert_match(/konnte nicht angelegt werden/, result.message)
    end
  end
end
