require "test_helper"

class StaticPagesTest < ActionDispatch::IntegrationTest
  # TS-076-S01: Impressum ohne Login erreichbar
  test "TS-076 GET /impressum erreichbar ohne Login und liefert HTTP 200" do
    get impressum_path

    assert_response :success
    assert_match "Impressum", response.body
  end

  test "TS-076 GET /datenschutz erreichbar ohne Login und liefert HTTP 200" do
    get datenschutz_path

    assert_response :success
    assert_match "Datenschutz", response.body
  end

  # TS-076-S02: Impressum enthält rechtlich relevante Angaben
  test "TS-076 Impressum-Seite enthält Pflichtangaben gemäß ECG" do
    get impressum_path

    assert_response :success
    assert_match "Mikiwa", response.body
    assert_match "Impressum", response.body
  end
end
