class MealCourse < ApplicationRecord
  include UuidPrimaryKey

  COURSE_TYPES   = %w[starter main dessert extra].freeze
  DIETARY_VALUES = %w[standard vegetarian vegan].freeze

  COURSE_LABELS = {
    "starter" => "Vorspeise",
    "main"    => "Hauptspeise",
    "dessert" => "Nachspeise",
    "extra"   => "Zusatzspeise"
  }.freeze

  DIETARY_LABELS = {
    "standard"   => "Standard",
    "vegetarian" => "Vegetarisch",
    "vegan"      => "Vegan"
  }.freeze

  belongs_to :meal_entry, inverse_of: :meal_courses

  validates :course_type, inclusion: { in: COURSE_TYPES }
  validates :name,        presence: true
  validates :dietary,     inclusion: { in: DIETARY_VALUES }
  validates :course_type, uniqueness: { scope: :meal_entry_id,
                                        message: "darf pro Tag und Gruppe nur einmal vorkommen" }

  scope :ordered, -> { order(:position, :course_type) }

  def label
    COURSE_LABELS[course_type] || course_type
  end

  def dietary_label
    DIETARY_LABELS[dietary] || dietary
  end

  COURSE_TYPES.each do |type|
    define_method("#{type}?") { course_type == type }
  end

  DIETARY_VALUES.each do |val|
    define_method("#{val}?") { dietary == val }
  end
end
