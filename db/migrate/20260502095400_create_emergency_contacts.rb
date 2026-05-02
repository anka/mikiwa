class CreateEmergencyContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :emergency_contacts, id: { type: :string, limit: 36 } do |t|
      t.string  :child_id,     limit: 36, null: false
      t.string  :name,         null: false
      t.string  :relationship, null: false
      t.string  :phone,        null: false
      t.integer :position,     default: 0, null: false
      t.timestamps
    end

    add_index :emergency_contacts, :child_id
    add_index :emergency_contacts, [ :child_id, :position ]
  end
end
