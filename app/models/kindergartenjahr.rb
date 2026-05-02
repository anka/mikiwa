class Kindergartenjahr < ApplicationRecord
  self.table_name = "kindergartenjahre"

  has_many :kinder, class_name: "Kind", dependent: :nullify

  validates :bezeichnung, presence: true
  validates :start_datum, presence: true
  validates :end_datum, presence: true

  before_save :deactivate_others, if: -> { aktiv? && aktiv_changed? }

  private

  def deactivate_others
    Kindergartenjahr.where(aktiv: true).where.not(id: id).update_all(aktiv: false)
  end
end
