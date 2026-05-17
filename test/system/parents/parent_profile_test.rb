require "test_helper"

class ParentProfileTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(
      email: "profile_parent@mikiwa.at",
      password: "sicherespasswort1234",
      role: "parent",
      first_name: "Eva",
      last_name: "Alt",
      phone: "0664 000 000"
    )
  end

  teardown do
    @parent.destroy!
  end

  # TS-032-S01: Elternteil aktualisiert Profil (Name, Telefon)
  test "TS-032 Elternteil kann Profil aktualisieren" do
    sign_in_as(@parent)

    patch profile_path, params: {
      user: { first_name: "Eva", last_name: "Neu", phone: "+43 664 9999999" }
    }

    assert_response :redirect

    @parent.reload
    assert_equal "Neu", @parent.last_name
    assert_equal "+43 664 9999999", @parent.phone
  end

  # TS-032-S02: Kein Formularfeld für Kinder-Zuordnung im Profil
  test "TS-032 Kinder-Zuordnung ist nicht über Profil änderbar" do
    sign_in_as(@parent)

    get profile_path

    assert_response :success
    assert_no_match "parent_children", response.body
    assert_no_match "child_ids", response.body
  end
end
