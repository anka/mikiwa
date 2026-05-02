class CreateAttendanceLists < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_lists, id: { type: :string, limit: 36 } do |t|
      t.string   :title,                null: false
      t.text     :description
      t.string   :mode,                 null: false, default: "general"
      t.datetime :deadline
      t.string   :group_id,             limit: 36, null: false
      t.string   :kindergarten_year_id, limit: 36, null: false
      t.string   :created_by_id,        limit: 36, null: false
      t.string   :event_id,             limit: 36
      t.timestamps
    end
    add_index :attendance_lists, :group_id
    add_index :attendance_lists, :kindergarten_year_id

    create_table :attendance_date_options, id: { type: :string, limit: 36 } do |t|
      t.string :attendance_list_id, limit: 36, null: false
      t.date   :date,               null: false
      t.timestamps
    end
    add_index :attendance_date_options, :attendance_list_id

    create_table :attendance_entries, id: { type: :string, limit: 36 } do |t|
      t.string   :attendance_list_id, limit: 36, null: false
      t.string   :child_id,           limit: 36, null: false
      t.string   :user_id,            limit: 36, null: false
      t.timestamps
    end
    add_index :attendance_entries, :attendance_list_id
    add_index :attendance_entries, [ :attendance_list_id, :child_id ], unique: true, name: "idx_entries_unique"

    create_table :attendance_date_selections, id: { type: :string, limit: 36 } do |t|
      t.string :attendance_entry_id,      limit: 36, null: false
      t.string :attendance_date_option_id, limit: 36, null: false
      t.timestamps
    end
    add_index :attendance_date_selections, :attendance_entry_id
    add_index :attendance_date_selections, [ :attendance_entry_id, :attendance_date_option_id ],
      unique: true, name: "idx_date_selections_unique"
  end
end
