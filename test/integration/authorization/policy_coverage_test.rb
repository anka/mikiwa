require "test_helper"

# TS-061-S01: Alle Controller-Actions sind durch Authentifizierung geschützt
class PolicyCoverageTest < ActionDispatch::IntegrationTest
  DUMMY_ID = "00000000-0000-0000-0000-000000000001"

  test "TS-061 alle geschützten GET-Endpunkte ohne ID leiten zu Login um" do
    routes = [
      children_path, new_child_path,
      parents_path, new_parent_path,
      profile_path,
      messages_path, new_message_path,
      inbox_path,
      birthdays_path,
      calendar_events_path, new_calendar_event_path,
      shopping_lists_path, new_shopping_list_path,
      attendance_lists_path, new_attendance_list_path,
      groups_path, new_group_path,
      kindergarten_years_path, new_kindergarten_year_path,
      staff_dashboard_path,
      parent_dashboard_path,
      polls_path, new_poll_path,
      meal_entries_path,
    ]

    routes.each do |path|
      get path
      assert_response :redirect, "#{path} sollte ohne Session zu Login umleiten"
      assert_redirected_to new_session_path, "#{path} leitet nicht zu Login"
    end
  end

  test "TS-061 alle geschützten GET-Endpunkte mit ID leiten zu Login um" do
    id = DUMMY_ID
    routes = [
      child_path(id), edit_child_path(id),
      calendar_event_path(id), edit_calendar_event_path(id),
      shopping_list_path(id), edit_shopping_list_path(id),
      attendance_list_path(id), edit_attendance_list_path(id),
      edit_group_path(id),
      edit_kindergarten_year_path(id),
      poll_path(id), edit_poll_path(id),
      inbox_message_path(id),
      gallery_path(id), edit_gallery_path(id),
    ]

    routes.each do |path|
      get path
      assert_response :redirect, "#{path} sollte ohne Session zu Login umleiten"
      assert_redirected_to new_session_path, "#{path} leitet nicht zu Login"
    end
  end
end
