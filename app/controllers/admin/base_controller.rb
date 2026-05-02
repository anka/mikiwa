class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    return if current_user&.admin?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
