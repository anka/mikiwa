class KindergartenYear < ApplicationRecord
  has_many :children, class_name: "Child", dependent: :nullify

  STATUSES = %w[planning active archived].freeze

  validates :label, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate  :only_one_active

  before_validation :archive_other_active, if: -> { status == "active" && status_changed? }
  before_save :sync_active_flag_from_status

  def active=(value)
    bool = ActiveModel::Type::Boolean.new.cast(value)
    if bool && status != "active"
      self.status = "active"
    elsif !bool && status == "active"
      self.status = "archived"
    end
    super(bool)
  end

  scope :planning_scope, -> { where(status: "planning") }
  scope :archived_scope, -> { where(status: "archived") }

  def self.active
    where(status: "active", active: true).first
  end

  def active?
    status == "active"
  end

  def planning?
    status == "planning"
  end

  def archived?
    status == "archived"
  end

  private

  def only_one_active
    return unless status == "active"
    conflict = KindergartenYear.where(status: "active").where.not(id: id).exists?
    return unless conflict
    errors.add(:status, "Es darf nur genau ein aktives Kindergartenjahr geben")
  end

  def archive_other_active
    KindergartenYear.where(status: "active").where.not(id: id).update_all(status: "archived", active: false)
  end

  # Beim Speichern Status → active-Flag spiegeln (für Backwards-Compat).
  def sync_active_flag_from_status
    desired = (status == "active")
    write_attribute(:active, desired) if active != desired
  end
end
