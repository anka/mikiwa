class ShoppingListsController < ApplicationController
  before_action :set_list,       only: %i[show edit update destroy]
  before_action :require_staff!, only: %i[new create edit update destroy]

  def index
    @lists = policy_scope(ShoppingList).includes(:group, :shopping_items).ordered
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
      :title, :description, :event_date, :group_id, :kindergarten_year_id
    )
    permitted[:group_id] = nil if permitted[:group_id].blank?
    permitted
  end

  def load_form_collections
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
