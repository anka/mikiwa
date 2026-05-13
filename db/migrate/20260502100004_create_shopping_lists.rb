class CreateShoppingLists < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_lists, id: { type: :string, limit: 36 } do |t|
      t.string  :title,                null: false
      t.text    :description
      t.date    :event_date,           null: false
      t.string  :group_id,             limit: 36, null: false
      t.string  :kindergarten_year_id, limit: 36, null: false
      t.string  :created_by_id,        limit: 36, null: false
      t.string  :event_id,             limit: 36
      t.timestamps
    end
    add_index :shopping_lists, :group_id
    add_index :shopping_lists, :kindergarten_year_id

    create_table :shopping_items, id: { type: :string, limit: 36 } do |t|
      t.string   :shopping_list_id, limit: 36, null: false
      t.string   :name,             null: false
      t.string   :quantity
      t.text     :note
      t.boolean  :done,             default: false, null: false
      t.string   :completed_by_id,  limit: 36
      t.datetime :completed_at
      t.integer  :position,         default: 0, null: false
      t.string   :category
      t.timestamps
    end
    add_index :shopping_items, :shopping_list_id
    add_index :shopping_items, [ :shopping_list_id, :position ]
    add_index :shopping_items, :category
  end
end
