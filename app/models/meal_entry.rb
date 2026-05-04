class MealEntry < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"

  has_many :meal_courses, -> { ordered }, dependent: :destroy, inverse_of: :meal_entry
  accepts_nested_attributes_for :meal_courses,
                                 allow_destroy: true,
                                 reject_if: ->(attrs) { attrs[:name].to_s.strip.blank? }

  validates :date,  presence: true
  validates :group, presence: true
  validates :date,  uniqueness: { scope: :group_id }
  validate  :must_have_at_least_one_course

  scope :for_week, ->(date) {
    start_date = date.beginning_of_week(:monday)
    end_date   = start_date + 4.days
    where(date: start_date..end_date).order(:date)
  }

  scope :ordered, -> { order(:date) }

  # F34: Liefert für jeden Course-Typ entweder den vorhandenen Course oder
  # einen neu gebauten leeren – sodass Forms und Views immer alle vier Slots
  # in fester Reihenfolge rendern können.
  def courses_by_type
    MealCourse::COURSE_TYPES.each_with_index.map do |type, idx|
      meal_courses.detect { |c| c.course_type == type } ||
        meal_courses.build(course_type: type, dietary: "standard", position: idx)
    end
  end

  private

  def must_have_at_least_one_course
    keepers = meal_courses.reject { |c| c.marked_for_destruction? || c.name.to_s.strip.blank? }
    return if keepers.any?
    errors.add(:base, "Mindestens eine Speise muss angegeben werden.")
  end
end
