require "test_helper"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parent = User.create!(
      email: "profil@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Elke",
      last_name: "Maier",
      phone: "0664 000 100"
    )
  end

  test "Elternteil kann eigenes Profil aufrufen" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
  end

  test "Elternteil kann Telefonnummer ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { phone: "0676 555 444" } }
    assert_equal "0676 555 444", @parent.reload.phone
    assert_redirected_to profile_path
  end

  test "Elternteil kann E-Mail ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { email: "neu@test.at" } }
    assert_equal "neu@test.at", @parent.reload.email
  end

  test "Elternteil kann Rolle nicht selbst ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { role: "admin" } }
    assert_equal "parent", @parent.reload.role
  end

  test "Profil zeigt iCal-Abo-Link" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
    assert_match ".ics", response.body
    assert @parent.reload.ical_token.present?
  end

  test "Token-Rotation erzeugt neuen Token" do
    sign_in_as(@parent)
    get profile_path
    old_token = @parent.reload.ical_token
    patch rotate_ical_token_profile_path
    assert_redirected_to profile_path
    assert_not_equal old_token, @parent.reload.ical_token
  end

  # F43: knowhow & notes
  test "F43 Elternteil kann knowhow ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { knowhow: "Tischler, Bastel-AGs" } }
    assert_equal "Tischler, Bastel-AGs", @parent.reload.knowhow
    assert_redirected_to profile_path
  end

  test "F43 Elternteil kann notes ändern" do
    sign_in_as(@parent)
    patch profile_path, params: { user: { notes: "Kind hat Pollenallergie" } }
    assert_equal "Kind hat Pollenallergie", @parent.reload.notes
  end

  test "F43 Profilformular zeigt knowhow- und notes-Felder" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
    assert_match(/name="user\[knowhow\]"/, response.body)
    assert_match(/name="user\[notes\]"/, response.body)
  end

  # F77: iCal-Link als webcal:// mit https-Fallback
  test "F77 Profil zeigt anklickbaren webcal://-Link" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
    token = @parent.reload.ical_token
    assert_select "a[href^='webcal://'][href$='/calendar/#{token}.ics']", text: /In Kalender-App öffnen/
  end

  test "F77 Profil zeigt https-URL mit clipboard-Button" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
    token = @parent.reload.ical_token
    https_url = "http://www.example.com/calendar/#{token}.ics"
    assert_select "[data-controller~='clipboard'][data-clipboard-text-value='#{https_url}']"
    assert_select "button[data-action*='clipboard#copy']", text: /Kopieren/
  end

  test "F77 Profil-Hilfetext erklärt beide Wege" do
    sign_in_as(@parent)
    get profile_path
    assert_response :success
    assert_match(/Kalender-App/i, response.body)
    assert_match(/kopieren/i, response.body)
  end

  test "F77 iCal-Endpoint liefert Content-Type text/calendar; charset=utf-8" do
    @parent.ensure_ical_token!
    get "/calendar/#{@parent.reload.ical_token}.ics"
    assert_response :success
    assert_match "text/calendar", response.content_type
    assert_match(/charset=utf-8/i, response.content_type)
  end
end
