class CreateAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :attendances, id: :string, limit: 36 do |t|
      t.references :child,              null: false, type: :string, limit: 36, foreign_key: true
      t.references :group,              null: false, type: :string, limit: 36, foreign_key: true
      t.references :kindergarten_year,  null: false, type: :string, limit: 36, foreign_key: true
      t.references :recorded_by,        null: false, type: :string, limit: 36, foreign_key: { to_table: :users }
      t.date    :date,                  null: false
      t.boolean :present,               null: false, default: true
      t.string  :absence_reason
      t.text    :note
      t.timestamps
    end

    add_index :attendances, %i[child_id date], unique: true
    add_index :attendances, %i[group_id date]
    add_index :attendances, %i[kindergarten_year_id date]
  end
end
