class AllowNullGroupOnShoppingLists < ActiveRecord::Migration[8.1]
  def up
    change_column_null :shopping_lists, :group_id, true
  end

  def down
    change_column_null :shopping_lists, :group_id, false
  end
end
