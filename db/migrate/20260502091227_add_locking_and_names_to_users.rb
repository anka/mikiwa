class AddLockingAndNamesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :locked_at, :datetime
    add_column :users, :first_name, :string, null: false, default: ""
    add_column :users, :last_name, :string, null: false, default: ""
    add_column :users, :invited_by_id, :string
    add_index :users, :invited_by_id
    add_column :users, :invitation_sent_at, :datetime
  end
end
