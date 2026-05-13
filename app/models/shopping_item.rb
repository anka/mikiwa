class ShoppingItem < ApplicationRecord
  include UuidPrimaryKey
  include ImageAttachable

  CATEGORY_ORDER = %w[
    fruit vegetable dairy meat_fish bakery beverages
    frozen sweets hygiene household craft_supplies other
  ].freeze

  CATEGORY_ICONS = {
    "fruit" => "leaf", "vegetable" => "sprout", "dairy" => "image",
    "meat_fish" => "image", "bakery" => "cake", "beverages" => "shopping-cart",
    "frozen" => "image", "sweets" => "gift", "hygiene" => "shield-check",
    "household" => "home", "craft_supplies" => "image-plus", "other" => "inbox"
  }.freeze

  enum :category, CATEGORY_ORDER.index_with(&:itself), prefix: true

  belongs_to :shopping_list
  belongs_to :completed_by, class_name: "User", optional: true

  has_one_attached :photo do |attachable|
    attachable.variant :thumb, **ImageAttachable::VARIANT_CONFIGS[:thumb]
  end

  validates :name, presence: true
  validates_image_attachment :photo

  scope :done,    -> { where(done: true) }
  scope :open,    -> { where(done: false) }
  scope :ordered, -> { order(:position, :created_at) }

  def complete!(user)
    update!(done: true, completed_by: user, completed_at: Time.current)
  end

  def uncomplete!
    update!(done: false, completed_by: nil, completed_at: nil)
  end
end
