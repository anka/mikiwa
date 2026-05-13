class AddPhoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone, :string, null: false, default: ""
  end
end
