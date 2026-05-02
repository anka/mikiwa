class GroupsController < ApplicationController
  before_action :require_staff!
  before_action :set_group, only: %i[edit update destroy]

  def index
    @groups = Group.order(:name)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    if @group.save
      redirect_to groups_path, notice: "Gruppe wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @group.update(group_params)
      redirect_to groups_path, notice: "Gruppe wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: "Gruppe wurde gelöscht."
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:name, :color, :description)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
