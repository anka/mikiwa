class AbstimmungOption < ApplicationRecord
  include UuidPrimaryKey

  self.table_name = "abstimmung_optionen"

  belongs_to :abstimmung
  has_many :stimmen, dependent: :destroy

  validates :label, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
