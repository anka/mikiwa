class PagesController < ApplicationController
  allow_unauthenticated_access only: %i[home offline]

  def home
  end

  def offline
  end
end
