class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[destroy lock unlock]

  def index
    @users = User.staff.order(:role, :last_name, :first_name)
  end

  def new
    @user = User.new(role: "caretaker")
  end

  def create
    @user = User.new(user_params)
    @user.invited_by = current_user
    @user.password = SecureRandom.hex(20)
    @user.invitation_sent_at = Time.current

    if @user.save
      InvitationMailer.invite(@user).deliver_later
      redirect_to admin_users_path, notice: "Einladung an #{@user.email} gesendet."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      render plain: "Sie können Ihren eigenen Account nicht löschen.", status: :unprocessable_entity
      return
    end
    @user.destroy
    redirect_to admin_users_path, notice: "Account wurde gelöscht."
  end

  def lock
    if @user == current_user
      render plain: "Sie können sich nicht selbst sperren.", status: :unprocessable_entity
      return
    end
    @user.lock!
    redirect_to admin_users_path, notice: "Account wurde gesperrt."
  end

  def unlock
    @user.unlock!
    redirect_to admin_users_path, notice: "Account wurde reaktiviert."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :role)
  end
end
