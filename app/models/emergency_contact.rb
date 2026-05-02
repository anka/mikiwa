class EmergencyContact < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :child

  encrypts :name
  encrypts :phone

  validates :name, :phone, :relationship, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  default_scope { order(:position) }
end
