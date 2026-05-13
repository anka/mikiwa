class ChildrenController < ApplicationController
  before_action :set_child, only: %i[show edit update deactivate update_consent attach_parent detach_parent]
  before_action :require_staff_for_mutations!, only: %i[new create deactivate]
  before_action :authorize_edit_update!, only: %i[edit update]

  def index
    @children = scoped_children.active.includes(:group, :parents).order(:last_name, :first_name)
  end

  def show
    authorize_child_access!(@child)
  end

  def new
    @child = Child.new(kindergarten_year: active_kindergarten_year)
  end

  def create
    @child = Child.new(child_params)
    if @child.save
      link_parent(@child)
      redirect_to children_path, notice: "#{@child.full_name} wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parent_edit = current_user.parent?
  end

  def update
    params_to_use = current_user.parent? ? parent_child_params : child_params
    if @child.update(params_to_use)
      target = current_user.parent? ? child_path(@child) : children_path
      redirect_to target, notice: "Stammdaten wurden aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def deactivate
    @child.deactivate!
    redirect_to children_path, notice: "#{@child.full_name} wurde deaktiviert."
  end

  def update_consent
    unless current_user.staff? || current_user.children.exists?(@child.id)
      render plain: "Zugriff verweigert", status: :forbidden
      return
    end
    consent = ActiveModel::Type::Boolean.new.cast(params.dig(:child, :photo_consent))
    @child.update_consent!(consent)
    redirect_to child_path(@child), notice: "Foto-Einwilligung wurde aktualisiert."
  end

  def attach_parent
    authorize!(@child, policy_class: ChildPolicy)
    parent = User.find_by(id: params[:user_id], role: "parent")
    if parent.nil?
      redirect_to child_path(@child), alert: "Kein passendes Eltern-Konto gefunden."
      return
    end

    ParentChild.find_or_create_by!(user: parent, child: @child)
    redirect_to child_path(@child), notice: "#{parent.full_name} wurde als Elternteil zugeordnet."
  end

  def detach_parent
    authorize!(@child, policy_class: ChildPolicy)
    link = @child.parent_children.find_by(user_id: params[:user_id])
    if link.nil?
      redirect_to child_path(@child), alert: "Diese Eltern-Zuordnung existiert nicht."
      return
    end

    name = link.user.full_name
    link.destroy!
    redirect_to child_path(@child), notice: "#{name} wurde von diesem Kind entfernt."
  end

  private

  def set_child
    @child = Child.find(params[:id])
  end

  def child_params
    params.require(:child).permit(
      :first_name, :last_name, :nickname, :date_of_birth,
      :group_id, :kindergarten_year_id, :photo_consent, :profile_photo,
      :health_insurer, :insurance_number
    )
  end

  def parent_child_params
    params.require(:child).permit(:insurance_number, :health_insurer)
  end

  def require_staff_for_mutations!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def authorize_edit_update!
    policy = ChildPolicy.new(current_user, @child)
    return if policy.edit?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def scoped_children
    return Child.all if current_user&.staff?
    current_user.children
  end

  def authorize_child_access!(child)
    return if current_user&.staff?
    return if current_user.children.exists?(child.id)
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def link_parent(child)
    parent_id = params.dig(:child, :parent_id)
    return unless parent_id.present?
    parent = User.find_by(id: parent_id, role: "parent")
    ParentChild.create!(user: parent, child: child) if parent
  end
end
