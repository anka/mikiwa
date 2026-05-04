class AddAssignedToToShoppingLists < ActiveRecord::Migration[8.1]
  def change
    add_column :shopping_lists, :assigned_to_id, :string, limit: 36
    add_index  :shopping_lists, :assigned_to_id
  end
end
