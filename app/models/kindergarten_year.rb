class KindergartenYear < ApplicationRecord
  has_many :children, class_name: "Child", dependent: :nullify

  validates :label, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  before_save :deactivate_others, if: -> { active? && active_changed? }

  def self.active
    find_by(active: true)
  end

  private

  def deactivate_others
    KindergartenYear.where(active: true).where.not(id: id).update_all(active: false)
  end
end
