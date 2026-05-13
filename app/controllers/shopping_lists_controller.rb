class ShoppingListsController < ApplicationController
  before_action :set_list,       only: %i[show edit update destroy]
  before_action :require_staff!, only: %i[new create edit update destroy]

  def index
    scope = policy_scope(ShoppingList).includes(:group, :assigned_to, :shopping_items)
    if params[:assigned] == "me" && current_user
      scope = scope.where(assigned_to_id: current_user.id)
    end
    scope = scope.where(group_id: params[:group_id]) if params[:group_id].present?
    scope = scope.where(assigned_to_id: params[:assigned_to_id]) if params[:assigned_to_id].present?
    if params[:month].present? && params[:month].to_s.match?(/\A\d{4}-\d{2}\z/)
      year, month = params[:month].split("-").map(&:to_i)
      first_day = Date.new(year, month, 1)
      scope = scope.where(event_date: first_day..first_day.end_of_month)
    end
    @lists = scope.ordered
    @assigned_filter = params[:assigned]
    @filter_group_id = params[:group_id]
    @filter_month = params[:month]
    @filter_assigned_to_id = params[:assigned_to_id]
    @filter_groups = Group.order(:name)
    @filter_assignees = User.where(id: ShoppingList.where.not(assigned_to_id: nil).distinct.pluck(:assigned_to_id)).order(:last_name, :first_name, :email)
    @filter_months = policy_scope(ShoppingList).pluck(:event_date).compact.map { |d| d.strftime("%Y-%m") }.uniq.sort.reverse
  end

  def show
    authorize!(@list, policy_class: ShoppingListPolicy)
    @items = @list.shopping_items.includes(:completed_by, photo_attachment: :blob).ordered
    @open_only = params[:filter] == "open"
    @items = @items.open if @open_only
  end

  def new
    @list = ShoppingList.new(kindergarten_year: active_kindergarten_year)
    load_form_collections
  end

  def create
    @list = ShoppingList.new(list_params)
    @list.kindergarten_year ||= active_kindergarten_year
    @list.created_by = current_user
    if @list.save
      redirect_to edit_shopping_list_path(@list),
                  notice: "Liste angelegt – jetzt Einträge hinzufügen."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @items    = @list.shopping_items.includes(photo_attachment: :blob).ordered
    @new_item = @list.shopping_items.build
    load_form_collections
  end

  def update
    if @list.update(list_params)
      redirect_to edit_shopping_list_path(@list), notice: "Liste aktualisiert."
    else
      @items    = @list.shopping_items.includes(photo_attachment: :blob).ordered
      @new_item = @list.shopping_items.build
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @list.destroy
    redirect_to shopping_lists_path, notice: "Liste wurde gelöscht."
  end

  private

  def set_list
    @list = ShoppingList.find(params[:id])
  end

  def list_params
    permitted = params.require(:shopping_list).permit(
      :title, :description, :event_date, :group_id, :kindergarten_year_id, :assigned_to_id
    )
    permitted[:group_id] = nil if permitted[:group_id].blank?
    permitted[:assigned_to_id] = nil if permitted[:assigned_to_id].blank?
    permitted
  end

  def load_form_collections
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
    @eligible_parents = eligible_parents_for(@list)
  end

  def eligible_parents_for(list)
    parents = User.where(role: "parent").order(:last_name, :first_name, :email)
    return parents if list.nil? || list.group_id.blank?

    parent_ids = ParentChild.joins(:child)
                            .where(children: { group_id: list.group_id, active: true })
                            .pluck(:user_id).uniq
    parents.where(id: parent_ids)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
