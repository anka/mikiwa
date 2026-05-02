class ChildrenController < ApplicationController
  before_action :set_child, only: %i[show edit update deactivate update_consent]
  before_action :require_staff_for_mutations!, only: %i[new create edit update deactivate]

  def index
    @children = scoped_children.active.includes(:group, :parents).order(:last_name, :first_name)
  end

  def show
    authorize_child_access!(@child)
  end

  def new
    @child = Child.new(kindergarten_year: active_year)
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

  def edit; end

  def update
    if @child.update(child_params)
      redirect_to children_path, notice: "Stammdaten wurden aktualisiert."
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

  def require_staff_for_mutations!
    return if current_user&.staff?
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

  def active_year
    KindergartenYear.find_by(active: true)
  end

  def link_parent(child)
    parent_id = params.dig(:child, :parent_id)
    return unless parent_id.present?
    parent = User.find_by(id: parent_id, role: "parent")
    ParentChild.create!(user: parent, child: child) if parent
  end
end
