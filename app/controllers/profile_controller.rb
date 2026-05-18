class ProfileController < ApplicationController
  before_action :ensure_ical_token, only: :show

  def show
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profil wurde aktualisiert."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def rotate_ical_token
    current_user.rotate_ical_token!
    redirect_to profile_path, notice: "Kalender-Token wurde zurückgesetzt. Bitte den neuen Link in Ihrer Kalender-App eintragen."
  end

  private

  def ensure_ical_token
    current_user.ensure_ical_token!
  end

  def profile_params
    permitted = [ :email, :first_name, :last_name, :phone, :knowhow ]
    permitted << :notes unless current_user.parent?
    params.require(:user).permit(*permitted)
  end
end
