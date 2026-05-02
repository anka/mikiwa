class ShoppingListsController < ApplicationController
  before_action :set_list,      only: %i[show edit update destroy]
  before_action :require_staff!, only: %i[new create edit update destroy]

  def index
    @lists = policy_scope(ShoppingList).includes(:group, :shopping_items).ordered
  end

  def show
    authorize!(@list, policy_class: ShoppingListPolicy)
    @items = @list.shopping_items.ordered
    @open_only = params[:filter] == "open"
    @items = @items.open if @open_only
  end

  def new
    @list = ShoppingList.new(kindergarten_year: active_year)
    @list.shopping_items.build
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def create
    @list = ShoppingList.new(list_params)
    @list.created_by = current_user
    if @list.save
      redirect_to shopping_list_path(@list), notice: "Einkaufsliste wurde angelegt."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def update
    if @list.update(list_params)
      redirect_to shopping_list_path(@list), notice: "Liste wurde aktualisiert."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
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
    params.require(:shopping_list).permit(
      :title, :description, :event_date, :group_id, :kindergarten_year_id,
      shopping_items_attributes: [ :id, :name, :quantity, :note, :_destroy ]
    )
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def active_year
    KindergartenYear.find_by(active: true)
  end
end
