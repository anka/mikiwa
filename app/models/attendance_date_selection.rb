class AttendanceDateSelection < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :attendance_entry
  belongs_to :attendance_date_option

  validates :attendance_date_option_id, uniqueness: { scope: :attendance_entry_id }
end
