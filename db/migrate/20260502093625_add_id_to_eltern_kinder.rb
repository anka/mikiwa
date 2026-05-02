class AddIdToElternKinder < ActiveRecord::Migration[8.1]
  def change
    # Recreate with UUID primary key (SQLite doesn't support ADD PRIMARY KEY)
    drop_table :eltern_kinder

    create_table :eltern_kinder, id: { type: :string, limit: 36 } do |t|
      t.string :user_id,  limit: 36, null: false
      t.string :kind_id,  limit: 36, null: false
      t.text   :bemerkung
      t.timestamps
    end

    add_index :eltern_kinder, [ :user_id, :kind_id ], unique: true
    add_index :eltern_kinder, :kind_id
  end
end
