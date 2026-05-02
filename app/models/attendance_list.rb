class AttendanceList < ApplicationRecord
  include UuidPrimaryKey

  MODES = %w[general per_date].freeze

  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  belongs_to :event, class_name: "Event", optional: true, foreign_key: :event_id

  has_many :attendance_date_options, dependent: :destroy
  has_many :attendance_entries, dependent: :destroy, class_name: "AttendanceEntry", foreign_key: :attendance_list_id

  accepts_nested_attributes_for :attendance_date_options, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
  validates :mode, inclusion: { in: MODES }
  validates :group, presence: true
  validates :kindergarten_year, presence: true
  validates :created_by, presence: true

  scope :for_group, ->(group) { where(group: group) }
  scope :ordered,   -> { order(created_at: :desc) }

  def deadline_passed?
    deadline.present? && deadline < Time.current
  end

  def open?
    !deadline_passed?
  end
end
