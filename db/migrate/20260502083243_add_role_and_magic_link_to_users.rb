class AddRoleAndMagicLinkToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "caretaker"
    add_column :users, :magic_link_token_version, :integer, null: false, default: 0
  end
end
