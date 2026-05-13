class CreateKindergartenYears < ActiveRecord::Migration[8.1]
  def change
    create_table :kindergarten_years, id: :string, limit: 36, force: :cascade do |t|
      t.string  :label,      null: false
      t.date    :start_date, null: false
      t.date    :end_date,   null: false
      t.boolean :active,     default: false, null: false
      t.string  :status,     default: "planning", null: false
      t.timestamps
    end
    add_index :kindergarten_years, :status
    add_index :kindergarten_years, :status,
              unique: true,
              where: "status = 'active'",
              name: "idx_kindergarten_years_active_singleton"
  end
end
