class CreateGalleries < ActiveRecord::Migration[8.1]
  def change
    create_table :galleries, id: :string, limit: 36 do |t|
      t.string  :title,               null: false
      t.text    :description
      t.date    :event_date
      t.references :kindergarten_year, null: false, type: :string, limit: 36, foreign_key: true
      t.references :created_by,       null: false, type: :string, limit: 36, foreign_key: { to_table: :users }
      t.string  :event_id,            limit: 36
      t.integer :visibility,          null: false, default: 0
      t.string  :slideshow_speed,     null: false, default: "normal"
      t.timestamps
    end

    add_index :galleries, :event_id

    create_table :gallery_groups, id: :string, limit: 36 do |t|
      t.references :gallery, null: false, type: :string, limit: 36, foreign_key: { to_table: :galleries }
      t.references :group,   null: false, type: :string, limit: 36, foreign_key: true
      t.timestamps
    end

    add_index :gallery_groups, %i[gallery_id group_id], unique: true

    create_table :photos, id: :string, limit: 36 do |t|
      t.references :gallery, null: false, type: :string, limit: 36,
                             foreign_key: { to_table: :galleries, on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.string  :caption,  limit: 200
      t.timestamps
    end

    add_index :photos, %i[gallery_id position]
  end
end
