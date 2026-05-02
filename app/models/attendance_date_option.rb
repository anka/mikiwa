class AttendanceDateOption < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :attendance_list
  has_many :attendance_date_selections, dependent: :destroy

  validates :date, presence: true
end
