class AddStatusToCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :calendar_events, :status, :string, default: "aktiv", null: false
  end
end
