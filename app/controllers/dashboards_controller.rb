class DashboardsController < ApplicationController
  def parent
    raise ApplicationPolicy::NotAuthorizedError unless current_user.parent?
    svc = ParentDashboardService.new(current_user)
    @unread_messages  = svc.unread_messages
    @upcoming_events  = svc.upcoming_events
    @open_lists       = svc.open_lists
    @open_polls       = svc.open_polls
    @upcoming_bdays   = svc.upcoming_birthdays
    @meal_entries     = svc.meal_entries
  end

  def staff
    raise ApplicationPolicy::NotAuthorizedError unless current_user.staff?
    svc = StaffDashboardService.new(current_user)
    @today_events         = svc.today_events
    @today_meals          = svc.today_meal_entries
    @today_birthdays      = svc.today_birthdays
    @events_without_gallery = svc.events_without_gallery
    @open_polls           = svc.open_polls
    @lists_without_entries = svc.lists_without_entries
    @children_without_consent = svc.children_without_consent
    @group_stats          = svc.group_statistics
    @active_year          = svc.active_year
  end
end
