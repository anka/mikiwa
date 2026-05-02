class PasswordsController < ApplicationController
  layout "auth"

  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Bitte versuchen Sie es später erneut." }

  def new
  end

  def create
    if user = User.find_by(email: params[:email])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Falls ein Konto mit dieser E-Mail-Adresse existiert, haben wir Anweisungen zum Zurücksetzen versendet."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Ihr Passwort wurde aktualisiert."
    else
      redirect_to edit_password_path(params[:token]), alert: "Die Passwörter stimmen nicht überein."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Der Link zum Zurücksetzen ist ungültig oder abgelaufen."
    end
end
