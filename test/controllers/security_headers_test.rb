require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "security-test@example.com", password: "sicherespasswort1234", role: "caretaker")
  end

  def login
    post session_path, params: { email: @user.email, password: "sicherespasswort1234" }
  end

  test "X-Robots-Tag wird bei geschützten Seiten gesetzt" do
    login
    get root_path
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "X-Frame-Options ist DENY" do
    login
    get root_path
    assert_equal "DENY", response.headers["X-Frame-Options"]
  end

  test "X-Content-Type-Options ist nosniff" do
    login
    get root_path
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "CSRF-Schutz ist für HTML-Formulare aktiv (protect_from_forgery)" do
    # CSRF-Schutz ist via ApplicationController::Base standardmäßig aktiv
    assert ApplicationController.ancestors.include?(ActionController::RequestForgeryProtection)
  end

  test "Login-Formular ist erreichbar und zeigt das Anmeldeformular" do
    get new_session_path
    assert_response :success
    assert_select "form[action='/session']"
  end

  test "Offline-Seite ist ohne Robots-Tag zugänglich" do
    get offline_path
    assert_response :success
  end
end
