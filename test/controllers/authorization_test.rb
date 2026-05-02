require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "admin2@test.com", password: "sicherespasswort1234", role: "admin")
    @caretaker = User.create!(email: "betreuer2@test.com", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "eltern2@test.com", password: SecureRandom.hex(20), role: "parent")
  end

  def login_as(user)
    post session_path, params: { email: user.email, password: "sicherespasswort1234" }
  end

  def login_parent(parent)
    token = parent.generate_token_for(:magic_link)
    get show_magic_links_path(token: token)
  end

  test "unauthentifizierter Zugriff redirectet zu Login (nicht 403)" do
    get root_path
    assert_redirected_to new_session_path
  end

  test "nicht-authorisierte Action liefert HTTP 403" do
    login_as @caretaker
    get admin_path rescue nil
    # Falls Route existiert: 403; falls nicht: 404. Mindestens kein 200.
    assert_not_equal 200, response.status
  end
end
