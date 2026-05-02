require "test_helper"

class TestFoundationTest < ActiveSupport::TestCase
  test "RuboCop-Konfiguration ist vorhanden" do
    assert File.exist?(Rails.root.join(".rubocop.yml")), "Keine .rubocop.yml"
  end

  test "Brakeman-Binary ist vorhanden" do
    assert File.exist?(Rails.root.join("bin/brakeman")), "Kein bin/brakeman"
  end

  test "CI-Pipeline-Datei existiert" do
    ci_file = Rails.root.join(".github/workflows/ci.yml")
    assert File.exist?(ci_file), "Keine CI-Pipeline"
    content = File.read(ci_file)
    assert_match "rails", content
    assert_match "brakeman", content
    assert_match "rubocop", content
  end

  test "Bundler-Audit-Binary ist vorhanden" do
    assert File.exist?(Rails.root.join("bin/bundler-audit")), "Kein bin/bundler-audit"
  end
end
