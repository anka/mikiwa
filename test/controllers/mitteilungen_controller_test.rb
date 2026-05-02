require "test_helper"

class MitteilungenControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_mc@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent    = User.create!(email: "eltern_mc@mikiwa.at",   password: SecureRandom.hex(20), role: "parent")
    @parent2   = User.create!(email: "eltern2_mc@mikiwa.at",  password: SecureRandom.hex(20), role: "parent")
    @year      = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @group_baeren = Group.create!(name: "Mitteil-Bären2")
    @group_loewen = Group.create!(name: "Mitteil-Löwen2")

    @child = Child.create!(
      first_name: "Leo", last_name: "Klein",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group_baeren, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @msg = Mitteilung.new(
      title: "Waldtag-Erinnerung",
      body: "Bitte wetterfeste Kleidung mitbringen.",
      sent_by: @caretaker
    )
    @msg.mitteilung_groups.build(group: @group_baeren)
    @msg.save!
    @msg.deliver!
  end

  # --- Auth ---
  test "unauthenticated user is redirected" do
    get posteingang_path
    assert_redirected_to new_session_path
  end

  # --- Posteingang (parent inbox) ---
  test "parent can view their inbox" do
    sign_in_as(@parent)
    get posteingang_path
    assert_response :success
    assert_match "Waldtag-Erinnerung", response.body
  end

  test "parent does not see messages for other groups" do
    sign_in_as(@parent2)
    get posteingang_path
    assert_response :success
    assert_no_match "Waldtag-Erinnerung", response.body
  end

  test "opening a message marks it as read" do
    sign_in_as(@parent)
    entry = Posteingang.find_by(user: @parent, mitteilung: @msg)
    assert_nil entry.read_at

    get posteingang_mitteilung_path(@msg)
    assert_response :success
    assert entry.reload.read?
  end

  # --- Gesendet (caretaker sent view) ---
  test "caretaker can view sent messages" do
    sign_in_as(@caretaker)
    get mitteilungen_path
    assert_response :success
    assert_match "Waldtag-Erinnerung", response.body
  end

  # --- Create ---
  test "caretaker can create and send a Mitteilung" do
    sign_in_as(@caretaker)
    assert_difference "Mitteilung.count", 1 do
      post mitteilungen_path, params: {
        mitteilung: {
          title: "Neue Nachricht",
          body: "Inhalt der Nachricht",
          group_ids: [ @group_baeren.id ]
        }
      }
    end
    new_msg = Mitteilung.order(:created_at).last
    assert_redirected_to mitteilungen_path
    assert Posteingang.exists?(mitteilung: new_msg, user: @parent)
  end

  test "parent cannot create Mitteilung (403)" do
    sign_in_as(@parent)
    post mitteilungen_path, params: {
      mitteilung: { title: "X", body: "B", group_ids: [ @group_baeren.id ] }
    }
    assert_response :forbidden
  end

  # --- E-Mail Benachrichtigung ---
  test "creating a Mitteilung enqueues email notifications" do
    sign_in_as(@caretaker)
    assert_enqueued_emails 1 do
      post mitteilungen_path, params: {
        mitteilung: {
          title: "Email-Test",
          body: "Nachrichtentext",
          group_ids: [ @group_baeren.id ]
        }
      }
    end
  end
end
