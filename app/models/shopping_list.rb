class ShoppingList < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :group, optional: true
  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  belongs_to :event, class_name: "Event", optional: true, foreign_key: :event_id
  belongs_to :assigned_to, class_name: "User", optional: true, foreign_key: :assigned_to_id

  has_many :shopping_items, -> { ordered }, dependent: :destroy, inverse_of: :shopping_list

  validates :title, presence: true
  validates :event_date, presence: true
  validates :kindergarten_year, presence: true
  validates :created_by, presence: true

  scope :ordered, -> { order(event_date: :desc) }
end
