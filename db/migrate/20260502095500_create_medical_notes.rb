class CreateMedicalNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :medical_notes, id: { type: :string, limit: 36 } do |t|
      t.string :child_id,  limit: 36, null: false
      t.string :note_type, null: false
      t.text   :content,   null: false
      t.timestamps
    end

    add_index :medical_notes, :child_id
  end
end
