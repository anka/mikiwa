class ParentsController < ApplicationController
  before_action :require_staff!, only: %i[index new create]
  before_action :set_parent, only: %i[show edit update lock unlock reinvite]
  before_action :authorize_parent!, only: %i[show edit update lock unlock reinvite]

  def index
    scope = User.where(role: "parent")
    if params[:q].present?
      term = "%#{params[:q].to_s.strip}%"
      scope = scope.where(
        "LOWER(first_name) LIKE LOWER(:t) OR LOWER(last_name) LIKE LOWER(:t) OR LOWER(email) LIKE LOWER(:t)",
        t: term
      )
    end
    @parents = scope.order(:last_name, :first_name)
    @search_query = params[:q].to_s
  end

  def new
    @user = User.new(role: "parent")
  end

  def create
    @user = User.new(parent_params)
    @user.role = "parent"
    @user.invited_by = current_user
    @user.password = SecureRandom.hex(20)
    @user.invitation_sent_at = Time.current

    if @user.save
      InvitationMailer.invite(@user).deliver_later
      redirect_to parents_path, notice: "Eltern-Account wurde angelegt und Einladung versandt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @children = @parent.children.includes(:group).order(:last_name, :first_name)
  end

  def edit
  end

  def update
    if @parent.update(parent_params)
      redirect_to parents_path, notice: "Stammdaten wurden aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def lock
    @parent.lock!
    redirect_to parents_path, notice: "Account wurde deaktiviert."
  end

  def unlock
    @parent.unlock!
    redirect_to parents_path, notice: "Account wurde reaktiviert."
  end

  def reinvite
    @parent.invalidate_magic_link_token!
    @parent.update!(invitation_sent_at: Time.current)
    InvitationMailer.invite(@parent).deliver_later
    redirect_to parents_path, notice: "Neue Einladungs-E-Mail wurde versendet."
  end

  private

  def set_parent
    @parent = User.find(params[:id])
  end

  def parent_params
    params.require(:user).permit(:email, :first_name, :last_name, :phone)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def authorize_parent!
    authorize!(@parent, policy_class: UserPolicy)
  end
end
