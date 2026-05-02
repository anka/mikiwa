class PagesController < ApplicationController
  allow_unauthenticated_access only: %i[offline home]

  def home
    return unless authenticated?
    redirect_to current_user.parent? ? parent_dashboard_path : staff_dashboard_path
  end

  def offline
  end
end
