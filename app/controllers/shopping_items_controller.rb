class ShoppingItemsController < ApplicationController
  before_action :set_list
  before_action :set_item, only: %i[complete uncomplete]

  def complete
    @item.complete!(current_user)
    redirect_to shopping_list_path(@list), notice: "Als erledigt markiert."
  end

  def uncomplete
    @item.uncomplete!
    redirect_to shopping_list_path(@list), notice: "Erledigt-Status aufgehoben."
  end

  private

  def set_list
    @list = ShoppingList.find(params[:shopping_list_id])
  end

  def set_item
    @item = @list.shopping_items.find(params[:id])
  end
end
