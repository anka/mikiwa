class AddIcalTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ical_token, :string
    add_index  :users, :ical_token, unique: true
  end
end
