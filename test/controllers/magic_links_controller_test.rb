require "test_helper"

class MagicLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(
      email: "eltern@test.com",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000"
    )
  end

  test "Magic-Link-Anfrage zeigt neutrale Bestätigung unabhängig vom Account" do
    post magic_links_path, params: { email: @parent.email }
    follow_redirect!
    assert_match "Falls ein Konto", response.body
  end

  test "Magic-Link-Anfrage mit unbekannter E-Mail zeigt dieselbe neutrale Meldung" do
    post magic_links_path, params: { email: "unknown@test.com" }
    follow_redirect!
    assert_match "Falls ein Konto", response.body
  end

  test "gültiger Magic-Link-Token öffnet Session" do
    token = @parent.generate_token_for(:magic_link)
    get show_magic_links_path(token: token)
    assert_response :redirect
    assert_not_nil response.cookies["session_id"]
  end

  test "ungültiger Magic-Link-Token öffnet keine Session" do
    get show_magic_links_path(token: "ungueltigertoken")
    assert_response :redirect
    assert_nil response.cookies["session_id"]
  end

  test "verwendeter Magic-Link-Token ist danach ungültig" do
    token = @parent.generate_token_for(:magic_link)

    # Erste Verwendung: Token gültig → Session geöffnet
    get show_magic_links_path(token: token)
    assert_response :redirect

    # Zweite Verwendung: Token ungültig → Redirect zum Formular mit Fehlermeldung
    get show_magic_links_path(token: token)
    assert_redirected_to new_magic_link_path
    assert_equal "Der Anmeldelink ist ungültig oder abgelaufen.", flash[:alert]
  end
end
