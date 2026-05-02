class SessionsController < ApplicationController
  layout "auth"

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Bitte versuchen Sie es später erneut." }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email, :password))
    if user&.locked?
      render :new, status: :unprocessable_entity, locals: { alert: "Dieser Account ist gesperrt." }
    elsif user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
