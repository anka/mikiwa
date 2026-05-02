class RecreateUsersWithUuid < ActiveRecord::Migration[8.1]
  def up
    drop_table :sessions
    drop_table :users

    create_table :users, id: :string, limit: 36, force: :cascade do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :email_invalid, default: false, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :sessions, id: :string, limit: 36, force: :cascade do |t|
      t.string :user_id, limit: 36, null: false
      t.string :user_agent
      t.string :ip_address
      t.timestamps
    end
    add_index :sessions, :user_id
    add_foreign_key :sessions, :users
  end

  def down
    drop_table :sessions
    drop_table :users

    create_table :users, force: :cascade do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :sessions, force: :cascade do |t|
      t.integer :user_id, null: false
      t.string :user_agent
      t.string :ip_address
      t.timestamps
    end
    add_index :sessions, :user_id
    add_foreign_key :sessions, :users
  end
end
