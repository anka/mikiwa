class Webhooks::BouncesController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

  def create
    email = params[:email].to_s.strip.downcase
    User.where(email: email).update_all(email_invalid: true)
    head :ok
  end
end
