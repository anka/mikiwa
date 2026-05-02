class CreateKindergartenjahre < ActiveRecord::Migration[8.1]
  def change
    create_table :kindergartenjahre, id: :string, limit: 36, force: :cascade do |t|
      t.string :bezeichnung, null: false
      t.date :start_datum, null: false
      t.date :end_datum, null: false
      t.boolean :aktiv, default: false, null: false
      t.timestamps
    end
  end
end
