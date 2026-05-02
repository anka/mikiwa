class ProfileController < ApplicationController
  def show
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profil wurde aktualisiert."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:email, :first_name, :last_name, :phone)
  end
end
