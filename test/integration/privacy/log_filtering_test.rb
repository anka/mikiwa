require "test_helper"

class LogFilteringTest < ActionDispatch::IntegrationTest
  # TS-014-S01: filter_parameters enthält PII-Felder
  test "filter_parameters enthält email, passwort und token" do
    params = Rails.application.config.filter_parameters

    filter = ActiveSupport::ParameterFilter.new(params)
    filtered = filter.filter(
      email: "user@test.de",
      password: "geheim1234",
      token: "abc123",
      name: "Sichtbar"
    )

    assert_equal "[FILTERED]", filtered[:email]
    assert_equal "[FILTERED]", filtered[:password]
    assert_equal "[FILTERED]", filtered[:token]
    assert_equal "Sichtbar", filtered[:name]
  end

  test "PII-Felder werden bei Login-Request aus Log-Params gefiltert" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    login_params = { "session" => { "email" => "user@test.de", "password" => "geheim1234" } }

    filtered = filter.filter(login_params)

    assert_equal "[FILTERED]", filtered["session"]["email"]
    assert_equal "[FILTERED]", filtered["session"]["password"]
  end
end
