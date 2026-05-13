require "test_helper"

class WhatsappShareTest < ActionDispatch::IntegrationTest
  setup do
    @group = Group.create!(name: "Share-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @staff  = User.create!(email: "staff_wa@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "parent_wa@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child  = Child.create!(
      first_name: "Erik", last_name: "Test",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)

    @event = Event.new(
      title: "Sommerfest", description: "Spaß für alle",
      start_date: Date.current + 7, all_day: true,
      kindergarten_year: @year, created_by: @staff
    )
    @event.groups << @group
    @event.save!

    @attendance_list = AttendanceList.create!(
      title: "Ausflug Juni",
      group: @group, kindergarten_year: @year, created_by: @staff
    )

    @poll = Poll.new(
      title: "Ausflugsziel", poll_type: "single",
      group: @group, kindergarten_year: @year, created_by: @staff
    )
    @poll.poll_options.build(label: "Wald")
    @poll.save!
  end

  # TS-052-S01: wa.me-Link enthält Titel und HTTPS-URL
  test "TS-052 WhatsApp-Link enthält Titel und HTTPS-Event-URL" do
    sign_in_as(@staff)
    get event_path(@event), headers: { "HOST" => "example.com" }

    assert_response :success
    assert_match "wa.me",                       response.body
    assert_match CGI.escape(@event.title),       response.body
    assert_match CGI.escape("http"),             response.body
  end

  # TS-052-S02: Veranstaltungs-URL ohne Session liefert 302
  test "TS-052 Event-URL ohne Login leitet auf Anmeldeseite weiter" do
    get event_path(@event)
    assert_response :redirect
    assert_redirected_to new_session_path
  end

  test "event show page contains WhatsApp share link" do
    sign_in_as(@staff)
    get event_path(@event)
    assert_response :success
    assert_match "wa.me", response.body
    assert_match CGI.escape(@event.title), response.body
  end

  test "attendance list show page contains WhatsApp share link" do
    sign_in_as(@staff)
    get attendance_list_path(@attendance_list)
    assert_response :success
    assert_match "wa.me", response.body
  end

  test "poll show page contains WhatsApp share link" do
    sign_in_as(@staff)
    get poll_path(@poll)
    assert_response :success
    assert_match "wa.me", response.body
  end

  test "parent can see WhatsApp share link on event" do
    sign_in_as(@parent)
    get event_path(@event)
    assert_response :success
    assert_match "wa.me", response.body
  end
end
