class MealEntry < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"

  validates :date,  presence: true
  validates :meal,  presence: true
  validates :group, presence: true
  validates :date,  uniqueness: { scope: :group_id }

  scope :for_week, ->(date) {
    start_date = date.beginning_of_week(:monday)
    end_date   = start_date + 4.days
    where(date: start_date..end_date).order(:date)
  }

  scope :ordered, -> { order(:date) }
end
