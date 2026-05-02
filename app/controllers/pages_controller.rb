class PagesController < ApplicationController
  allow_unauthenticated_access only: :offline

  def home
  end

  def offline
  end
end
