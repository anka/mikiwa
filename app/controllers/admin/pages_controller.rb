class Admin::PagesController < ApplicationController
  allow_unauthenticated_access only: %i[impressum datenschutz]

  def impressum
  end

  def datenschutz
  end
end
