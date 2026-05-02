require "test_helper"

class ParentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_p@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(
      email: "eltern_p@mikiwa.at",
      password: SecureRandom.hex(20),
      role: "parent",
      first_name: "Anna",
      last_name: "Huber",
      phone: "0664 123 456"
    )
  end

  test "Betreuer kann Eltern-Liste aufrufen" do
    sign_in_as(@caretaker)
    get parents_path
    assert_response :success
  end

  test "Elternteil kann Eltern-Liste nicht aufrufen (403)" do
    sign_in_as(@parent)
    get parents_path
    assert_response :forbidden
  end

  test "Betreuer kann Eltern-Account anlegen und Einladungs-Mail wird versandt" do
    sign_in_as(@caretaker)
    assert_emails 1 do
      assert_difference "User.count", 1 do
        post parents_path, params: {
          user: {
            email: "neues.elternteil@test.at",
            first_name: "Max",
            last_name: "Muster",
            phone: "0650 999 888"
          }
        }
      end
    end
    new_parent = User.find_by!(email: "neues.elternteil@test.at")
    assert_equal "parent", new_parent.role
    assert_equal "Max", new_parent.first_name
    assert_redirected_to parents_path
  end

  test "Betreuer kann Eltern-Account deaktivieren" do
    sign_in_as(@caretaker)
    patch lock_parent_path(@parent)
    assert @parent.reload.locked?
  end

  test "Betreuer kann Re-Einladung senden" do
    sign_in_as(@caretaker)
    assert_emails 1 do
      post reinvite_parent_path(@parent)
    end
    assert_redirected_to parents_path
  end

  test "Re-Einladung invalidiert vorherigen Token" do
    sign_in_as(@caretaker)
    old_version = @parent.magic_link_token_version
    post reinvite_parent_path(@parent)
    assert_operator @parent.reload.magic_link_token_version, :>, old_version
  end
end
