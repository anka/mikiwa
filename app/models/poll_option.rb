class PollOption < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :poll
  has_many :votes, dependent: :destroy

  validates :label, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
