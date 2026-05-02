class CreateNotfallkontakte < ActiveRecord::Migration[8.1]
  def change
    create_table :notfallkontakte, id: { type: :string, limit: 36 } do |t|
      t.string  :kind_id,   limit: 36, null: false
      t.string  :name,      null: false
      t.string  :beziehung, null: false
      t.string  :telefon,   null: false
      t.integer :position,  default: 0, null: false
      t.timestamps
    end

    add_index :notfallkontakte, :kind_id
    add_index :notfallkontakte, [ :kind_id, :position ]
  end
end
