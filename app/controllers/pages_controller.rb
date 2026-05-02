class PagesController < ApplicationController
  allow_unauthenticated_access only: %i[offline home]

  def home
    redirect_to children_path if authenticated?
  end

  def offline
  end
end
