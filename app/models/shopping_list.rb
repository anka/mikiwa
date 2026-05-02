class ShoppingList < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :group
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  belongs_to :event, class_name: "Event", optional: true, foreign_key: :event_id

  has_many :shopping_items, dependent: :destroy

  accepts_nested_attributes_for :shopping_items, allow_destroy: true, reject_if: :all_blank

  validates :title, presence: true
  validates :event_date, presence: true
  validates :group, presence: true
  validates :kindergarten_year, presence: true
  validates :created_by, presence: true

  scope :ordered, -> { order(event_date: :desc) }
end
