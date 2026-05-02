class CreateKindergartenYears < ActiveRecord::Migration[8.1]
  def change
    create_table :kindergarten_years, id: :string, limit: 36, force: :cascade do |t|
      t.string  :label,      null: false
      t.date    :start_date, null: false
      t.date    :end_date,   null: false
      t.boolean :active,     default: false, null: false
      t.timestamps
    end
  end
end
