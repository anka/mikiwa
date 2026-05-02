class MagicLinksController < ApplicationController
  layout "auth"

  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, only: :create,
             with: -> { redirect_to new_magic_link_path, alert: "Bitte versuchen Sie es später erneut." }

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase, role: "parent")
    MagicLinkMailer.login(user).deliver_later if user && !user.email_invalid?
    redirect_to new_session_path,
      notice: "Falls ein Konto mit dieser E-Mail-Adresse existiert, haben wir einen Anmeldelink versendet."
  end

  def show
    user = User.find_by_token_for(:magic_link, params[:token])
    if user
      user.invalidate_magic_link_token!
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_magic_link_path, alert: "Der Anmeldelink ist ungültig oder abgelaufen."
    end
  end
end
