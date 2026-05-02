require "test_helper"

class GruppenControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin_g@mikiwa.at", password: "adminpasswort1234567", role: "admin")
    @caretaker = User.create!(email: "betreuer_g@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "eltern_g@mikiwa.at", password: SecureRandom.hex(20), role: "parent")
    @gruppe = Gruppe.create!(name: "Bären")
  end

  test "Betreuer kann Gruppen-Liste aufrufen" do
    sign_in_as(@caretaker)
    get gruppen_index_path
    assert_response :success
  end

  test "Elternteil kann Gruppen-Liste nicht aufrufen (403)" do
    sign_in_as(@parent)
    get gruppen_index_path
    assert_response :forbidden
  end

  test "Betreuer kann neue Gruppe anlegen" do
    sign_in_as(@caretaker)
    assert_difference "Gruppe.count", 1 do
      post gruppen_index_path, params: { gruppe: { name: "Schmetterlinge", farbe: "#FF6B6B", beschreibung: "Unsere Kleinen" } }
    end
    assert_redirected_to gruppen_index_path
  end

  test "Gruppe ohne Namen wird abgelehnt" do
    sign_in_as(@caretaker)
    assert_no_difference "Gruppe.count" do
      post gruppen_index_path, params: { gruppe: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "Betreuer kann Gruppe bearbeiten" do
    sign_in_as(@caretaker)
    patch gruppen_path(@gruppe), params: { gruppe: { name: "Neue Bären", farbe: "#00AA00" } }
    assert_equal "Neue Bären", @gruppe.reload.name
    assert_equal "#00AA00", @gruppe.reload.farbe
  end

  test "Betreuer kann Gruppe löschen" do
    sign_in_as(@caretaker)
    assert_difference "Gruppe.count", -1 do
      delete gruppen_path(@gruppe)
    end
  end
end
