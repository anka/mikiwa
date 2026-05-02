class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups, id: :string, limit: 36, force: :cascade do |t|
      t.string :name, null: false
      t.string :color
      t.text :description
      t.timestamps
    end
  end
end
