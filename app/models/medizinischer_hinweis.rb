class MedizinischerHinweis < ApplicationRecord
  include UuidPrimaryKey

  self.table_name = "medizinische_hinweise"

  TYPEN = %w[allergie medikament besonderheit].freeze

  belongs_to :kind

  encrypts :inhalt

  validates :hinweis_typ, presence: true, inclusion: { in: TYPEN }
  validates :inhalt, presence: true
end
