class Attendance < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :child
  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :recorded_by, class_name: "User"

  ABSENCE_REASONS = %w[sick vacation appointment other].freeze
  ABSENCE_REASON_LABELS = {
    "sick"        => "Krank",
    "vacation"    => "Urlaub",
    "appointment" => "Termin",
    "other"       => "Sonstiges"
  }.freeze

  enum :absence_reason, ABSENCE_REASONS.index_with(&:itself), prefix: true

  validates :date, presence: true, uniqueness: { scope: :child_id, message: "wurde für dieses Kind bereits erfasst" }
  validate  :absence_reason_only_when_absent

  scope :for_date,  ->(date)     { where(date: date) }
  scope :for_group, ->(group_id) { where(group_id: group_id) }
  scope :for_child, ->(child_id) { where(child_id: child_id) }
  scope :in_month,  ->(date)     { where(date: date.beginning_of_month..date.end_of_month) }

  private

  def absence_reason_only_when_absent
    return if absence_reason.blank?
    return unless present
    errors.add(:absence_reason, "nur bei Abwesenheit erlaubt")
  end
end
