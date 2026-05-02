class MedicalNote < ApplicationRecord
  include UuidPrimaryKey

  TYPES = %w[allergy medication special_note].freeze

  belongs_to :child

  encrypts :content

  validates :note_type, presence: true, inclusion: { in: TYPES }
  validates :content, presence: true
end
