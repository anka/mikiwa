class CreateKinder < ActiveRecord::Migration[8.1]
  def change
    create_table :kinder, id: { type: :string, limit: 36 } do |t|
      t.string  :vorname, null: false
      t.string  :nachname, null: false
      t.string  :rufname
      t.date    :geburtsdatum, null: false
      t.string  :gruppe_id, limit: 36, null: false
      t.string  :kindergartenjahr_id, limit: 36, null: false
      t.boolean :foto_einwilligung, null: false
      t.boolean :aktiv, null: false, default: true
      t.timestamps
    end

    add_index :kinder, :gruppe_id
    add_index :kinder, :kindergartenjahr_id

    create_table :eltern_kinder, id: false do |t|
      t.string :user_id,  limit: 36, null: false
      t.string :kind_id,  limit: 36, null: false
      t.text   :bemerkung
      t.timestamps
    end

    add_index :eltern_kinder, [ :user_id, :kind_id ], unique: true
    add_index :eltern_kinder, :kind_id
  end
end
