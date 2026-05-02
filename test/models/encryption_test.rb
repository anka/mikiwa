require "test_helper"

class EncryptionTest < ActiveSupport::TestCase
  test "Sensible Parameter werden in Logs gefiltert" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    params = { email: "user@example.com", password: "secret", token: "abc123", name: "Test" }
    filtered = filter.filter(params)

    assert_equal "[FILTERED]", filtered[:email]
    assert_equal "[FILTERED]", filtered[:password]
    assert_equal "[FILTERED]", filtered[:token]
    assert_equal "Test", filtered[:name]
  end

  test "Session-Cookie ist httpOnly und SameSite=Lax konfiguriert" do
    # Prüfen, dass der Authentication-Concern die richtigen Flags setzt
    # (Integrations-Test validiert das vollständig)
    auth_concern = Authentication.instance_method(:start_new_session_for).source_location.first
    source = File.read(auth_concern)
    assert_match "httponly: true", source
    assert_match "same_site: :lax", source
    assert_match "expires: 7.days", source
  end
end
