class AttendanceEntry < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :list, class_name: "AttendanceList", foreign_key: :attendance_list_id
  belongs_to :child
  belongs_to :user

  has_many :attendance_date_selections, dependent: :destroy

  validates :child_id, uniqueness: { scope: :attendance_list_id, message: "ist bereits eingetragen" }
  validates :child,    presence: true
  validates :user,     presence: true

  scope :ordered, -> { order(:created_at) }
end
