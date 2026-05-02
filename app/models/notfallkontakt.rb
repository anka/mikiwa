class Notfallkontakt < ApplicationRecord
  include UuidPrimaryKey

  self.table_name = "notfallkontakte"

  belongs_to :kind

  encrypts :name
  encrypts :telefon

  validates :name, :telefon, :beziehung, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  default_scope { order(:position) }
end
