class CalendarEvent < ApplicationRecord
  include UuidPrimaryKey

  EVENT_TYPES = %w[event veranstaltung].freeze
  STATUSES    = %w[aktiv abgesagt].freeze

  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  has_many :calendar_event_groups, dependent: :destroy
  has_many :groups, through: :calendar_event_groups

  validates :title, presence: true
  validates :start_date, presence: true
  validates :kindergarten_year, presence: true
  validates :created_by, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validate  :at_least_one_group
  validates :start_time, presence: true, if: -> { !all_day }

  scope :for_year,        ->(year) { where(kindergarten_year: year) }
  scope :veranstaltungen, -> { where(event_type: "veranstaltung") }
  scope :for_month,  ->(date) { where(start_date: date.beginning_of_month..date.end_of_month) }
  scope :for_groups, ->(ids)  { joins(:calendar_event_groups).where(calendar_event_groups: { group_id: ids }).distinct }
  scope :ordered,    -> { order(:start_date, :start_time) }

  private

  def at_least_one_group
    active_groups = calendar_event_groups.reject(&:marked_for_destruction?)
    errors.add(:groups, "mindestens eine Gruppe muss zugeordnet sein") if active_groups.empty?
  end
end
