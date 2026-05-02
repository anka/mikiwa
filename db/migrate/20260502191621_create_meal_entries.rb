class CreateMealEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_entries, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.date   :date, null: false
      t.string :meal, null: false
      t.text   :notes

      t.references :group,             null: false, type: :string, foreign_key: true
      t.references :kindergarten_year, null: false, type: :string, foreign_key: true
      t.references :created_by,        null: false, type: :string, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :meal_entries, %i[date group_id], unique: true
  end
end
