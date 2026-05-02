class CreateMedizinischeHinweise < ActiveRecord::Migration[8.1]
  def change
    create_table :medizinische_hinweise, id: { type: :string, limit: 36 } do |t|
      t.string :kind_id,     limit: 36, null: false
      t.string :hinweis_typ, null: false
      t.text   :inhalt,      null: false
      t.timestamps
    end

    add_index :medizinische_hinweise, :kind_id
  end
end
