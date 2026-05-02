class CreateAbstimmungen < ActiveRecord::Migration[8.1]
  def change
    create_table :abstimmungen, id: :string, limit: 36 do |t|
      t.string  :title,               null: false
      t.text    :description
      t.string  :poll_type,           null: false, default: "einfach"
      t.string  :status,              null: false, default: "offen"
      t.datetime :deadline
      t.references :group,            null: false, type: :string, limit: 36, foreign_key: true
      t.references :kindergarten_year, null: false, type: :string, limit: 36, foreign_key: true
      t.references :created_by,       null: false, type: :string, limit: 36, foreign_key: { to_table: :users }
      t.string  :event_id,            limit: 36
      t.timestamps
    end

    add_index :abstimmungen, :event_id

    create_table :abstimmung_optionen, id: :string, limit: 36 do |t|
      t.references :abstimmung, null: false, type: :string, limit: 36,
                   foreign_key: { to_table: :abstimmungen }
      t.string  :label,    null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :stimmen, id: :string, limit: 36 do |t|
      t.references :abstimmung_option, null: false, type: :string, limit: 36,
                   foreign_key: { to_table: :abstimmung_optionen }
      t.references :user, null: false, type: :string, limit: 36, foreign_key: true
      t.timestamps
    end

    add_index :stimmen, %i[abstimmung_option_id user_id], unique: true
  end
end
