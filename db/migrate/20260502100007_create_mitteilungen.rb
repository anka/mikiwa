class CreateMitteilungen < ActiveRecord::Migration[8.1]
  def change
    create_table :mitteilungen, id: :string, limit: 36 do |t|
      t.string :title,       null: false
      t.text   :body,        null: false
      t.references :sent_by, null: false, type: :string, limit: 36, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :mitteilung_groups, id: :string, limit: 36 do |t|
      t.references :mitteilung, null: false, type: :string, limit: 36,
                   foreign_key: { to_table: :mitteilungen }
      t.references :group, null: false, type: :string, limit: 36, foreign_key: true
      t.timestamps
    end

    add_index :mitteilung_groups, %i[mitteilung_id group_id], unique: true

    create_table :posteingaenge, id: :string, limit: 36 do |t|
      t.references :mitteilung, null: false, type: :string, limit: 36,
                   foreign_key: { to_table: :mitteilungen }
      t.references :user, null: false, type: :string, limit: 36, foreign_key: true
      t.datetime :read_at
      t.timestamps
    end

    add_index :posteingaenge, %i[mitteilung_id user_id], unique: true
  end
end
