class CreateEmergencyContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :emergency_contacts, id: { type: :string, limit: 36 } do |t|
      t.string  :child_id,     limit: 36, null: false
      t.string  :user_id,      limit: 36, null: true
      t.string  :name,         null: true
      t.string  :relationship, null: false
      t.string  :phone,        null: true
      t.integer :position,     default: 0, null: false
      t.timestamps
    end

    add_index :emergency_contacts, :child_id
    add_index :emergency_contacts, [ :child_id, :position ]
    add_index :emergency_contacts, :user_id
    add_foreign_key :emergency_contacts, :users, column: :user_id, on_delete: :nullify
  end
end
