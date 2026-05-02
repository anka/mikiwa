class CreateCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_events, id: { type: :string, limit: 36 } do |t|
      t.string  :title,               null: false
      t.date    :start_date,          null: false
      t.boolean :all_day,             null: false, default: true
      t.string  :start_time
      t.string  :location
      t.text    :description
      t.string  :event_type,          null: false, default: "event"
      t.string  :kindergarten_year_id, limit: 36, null: false
      t.string  :created_by_id,       limit: 36, null: false
      t.timestamps
    end

    add_index :calendar_events, :kindergarten_year_id
    add_index :calendar_events, :start_date
    add_index :calendar_events, :created_by_id

    create_table :calendar_event_groups, id: { type: :string, limit: 36 } do |t|
      t.string :calendar_event_id, limit: 36, null: false
      t.string :group_id,          limit: 36, null: false
      t.timestamps
    end

    add_index :calendar_event_groups, :calendar_event_id
    add_index :calendar_event_groups, [ :calendar_event_id, :group_id ], unique: true, name: "idx_cal_event_groups_unique"
  end
end
