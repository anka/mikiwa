class CreateChildren < ActiveRecord::Migration[8.1]
  def change
    create_table :children, id: { type: :string, limit: 36 } do |t|
      t.string  :first_name,           null: false
      t.string  :last_name,            null: false
      t.string  :nickname
      t.date    :date_of_birth,        null: false
      t.string  :group_id,             limit: 36, null: false
      t.string  :kindergarten_year_id, limit: 36, null: false
      t.boolean :photo_consent,        null: false
      t.boolean :active,               null: false, default: true
      t.string  :health_insurer
      t.string  :insurance_number
      t.timestamps
    end

    add_index :children, :group_id
    add_index :children, :kindergarten_year_id

    create_table :parent_children, id: { type: :string, limit: 36 } do |t|
      t.string :user_id,  limit: 36, null: false
      t.string :child_id, limit: 36, null: false
      t.text   :note
      t.timestamps
    end

    add_index :parent_children, [ :user_id, :child_id ], unique: true
    add_index :parent_children, :child_id
  end
end
