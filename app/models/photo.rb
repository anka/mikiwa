class Photo < ApplicationRecord
  include UuidPrimaryKey
  include ImageAttachable

  belongs_to :gallery

  has_one_attached :image do |attachable|
    ImageAttachable::VARIANT_CONFIGS.each do |name, config|
      attachable.variant name, **config
    end
  end

  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :caption, length: { maximum: 200 }, allow_blank: true
  validates_image_attachment :image
  validate :image_must_be_attached, on: :create

  scope :in_order, -> { order(:position, :created_at) }

  before_validation :assign_default_position, on: :create

  private

  def image_must_be_attached
    errors.add(:image, "muss angehängt sein") unless image.attached?
  end

  def assign_default_position
    return if position.present? && position.positive?
    max = gallery&.photos&.maximum(:position) || 0
    self.position = max + 1
  end
end
