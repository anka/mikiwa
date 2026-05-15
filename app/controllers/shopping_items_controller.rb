class ShoppingItemsController < ApplicationController
  before_action :set_list
  before_action :require_staff_for_management!,  only: %i[create update destroy purge_photo]
  before_action :set_item,                       only: %i[update destroy purge_photo complete uncomplete]
  before_action :authorize_item!,                only: %i[complete uncomplete]

  def create
    @item = @list.shopping_items.build(item_params)
    @item.position = next_position

    if @item.save
      respond_to do |format|
        format.turbo_stream { render_create_streams }
        format.html { redirect_to edit_shopping_list_path(@list) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_new_form_with_errors }
        format.html { redirect_to edit_shopping_list_path(@list), alert: @item.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream { render_item_replace }
        format.html { redirect_to edit_shopping_list_path(@list) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_item_replace(status: :unprocessable_entity) }
        format.html { redirect_to edit_shopping_list_path(@list), alert: @item.errors.full_messages.to_sentence }
      end
    end
  rescue ArgumentError => e
    # F78: Enum-Setter wirft bei ungültigem Wert (z.B. category='ungueltig')
    @item.errors.add(:category, "ist ungültig")
    respond_to do |format|
      format.turbo_stream { render_item_replace(status: :unprocessable_entity) }
      format.html { redirect_to edit_shopping_list_path(@list), alert: e.message }
    end
  end

  def destroy
    @item.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@item),
          summary_stream
        ]
      end
      format.html { redirect_to edit_shopping_list_path(@list), notice: "Eintrag entfernt." }
    end
  end

  def purge_photo
    @item.photo.purge_later
    respond_to do |format|
      format.turbo_stream { render_item_replace }
      format.html { redirect_to edit_shopping_list_path(@list), notice: "Bild entfernt." }
    end
  end

  def complete
    @item.complete!(current_user)
    respond_with_toggle("Als erledigt markiert.")
  end

  def uncomplete
    @item.uncomplete!
    respond_with_toggle("Erledigt-Status aufgehoben.")
  end

  private

  def set_list
    @list = ShoppingList.find(params[:shopping_list_id])
  end

  def set_item
    @item = @list.shopping_items.find(params[:id])
  end

  def item_params
    permitted = params.require(:shopping_item).permit(:name, :quantity, :note, :photo, :category)
    permitted[:category] = nil if permitted[:category].blank?
    permitted
  end

  def next_position
    (@list.shopping_items.maximum(:position) || -1) + 1
  end

  def render_create_streams
    render turbo_stream: [
      turbo_stream.append("shopping_items", partial: "shopping_items/item",
                                             locals: { item: @item }),
      turbo_stream.replace("new_shopping_item", partial: "shopping_items/form",
                                                  locals: { list: @list,
                                                            item: @list.shopping_items.build,
                                                            focus_on_connect: true }),
      summary_stream
    ]
  end

  def render_new_form_with_errors
    render turbo_stream: turbo_stream.replace("new_shopping_item",
                                                partial: "shopping_items/form",
                                                locals: { list: @list, item: @item }),
           status: :unprocessable_entity
  end

  def render_item_replace(status: :ok)
    render turbo_stream: turbo_stream.replace(@item, partial: "shopping_items/item",
                                                      locals: { item: @item }),
           status: status
  end

  def respond_with_toggle(notice_text)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@item, partial: "shopping_items/show_item",
                                       locals: { item: @item, list: @list }),
          summary_stream
        ]
      end
      format.html { redirect_to shopping_list_path(@list), notice: notice_text }
    end
  end

  def summary_stream
    turbo_stream.replace("shopping_items_summary", partial: "shopping_items/summary",
                                                    locals: { list: @list })
  end

  def authorize_item!
    authorize!(@item, policy_class: ShoppingItemPolicy)
  end

  def require_staff_for_management!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
