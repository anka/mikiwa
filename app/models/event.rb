class Event < ApplicationRecord
  include UuidPrimaryKey

  self.table_name = "calendar_events"

  STATUSES = %w[aktiv abgesagt].freeze

  default_scope { where(event_type: "veranstaltung") }

  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  has_many :calendar_event_groups, foreign_key: :calendar_event_id, dependent: :destroy, inverse_of: :calendar_event
  has_many :groups, through: :calendar_event_groups

  before_create { self.event_type = "veranstaltung" }
  before_create { self.status ||= "aktiv" }

  validates :title,             presence: true
  validates :start_date,        presence: true
  validates :kindergarten_year, presence: true
  validates :created_by,        presence: true
  validates :status,            inclusion: { in: STATUSES }
  validates :start_time,        presence: true, if: -> { !all_day }
  validate  :at_least_one_group

  scope :for_year,   ->(year) { where(kindergarten_year: year) }
  scope :for_groups, ->(ids)  { joins(:calendar_event_groups).where(calendar_event_groups: { group_id: ids }).distinct }
  scope :ordered,    -> { order(:start_date, :start_time) }
  scope :active,     -> { where(status: "aktiv") }
  scope :cancelled,  -> { where(status: "abgesagt") }

  def cancel!
    update!(status: "abgesagt")
  end

  def cancelled?
    status == "abgesagt"
  end

  private

  def at_least_one_group
    active_groups = calendar_event_groups.reject(&:marked_for_destruction?)
    errors.add(:groups, "mindestens eine Gruppe muss zugeordnet sein") if active_groups.empty?
  end
end
