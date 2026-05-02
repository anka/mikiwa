class CreateGruppen < ActiveRecord::Migration[8.1]
  def change
    create_table :gruppen, id: :string, limit: 36, force: :cascade do |t|
      t.string :name, null: false
      t.string :farbe
      t.text :beschreibung
      t.timestamps
    end
  end
end
