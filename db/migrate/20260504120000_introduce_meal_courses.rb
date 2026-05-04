class IntroduceMealCourses < ActiveRecord::Migration[8.1]
  def change
    # F34: meal:string entfällt, ersetzt durch separates MealCourse-Modell.
    # Datenbank wird bewusst neu aufgesetzt – keine Migration alter Werte.
    remove_column :meal_entries, :meal, :string, null: false

    create_table :meal_courses, id: false do |t|
      t.string :id, null: false, primary_key: true

      t.string :course_type, null: false  # starter / main / dessert / extra
      t.string :name,        null: false
      t.string :dietary,     null: false, default: "standard"  # standard / vegetarian / vegan
      t.integer :position,   null: false, default: 0

      t.references :meal_entry, null: false, type: :string, foreign_key: true

      t.timestamps
    end

    add_index :meal_courses, [ :meal_entry_id, :course_type ], unique: true,
              name: "index_meal_courses_on_entry_and_type"
  end
end
