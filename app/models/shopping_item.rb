class ShoppingItem < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :shopping_list
  belongs_to :completed_by, class_name: "User", optional: true

  validates :name, presence: true

  scope :open,    -> { where(done: false) }
  scope :ordered, -> { order(:position, :created_at) }

  def complete!(user)
    update!(done: true, completed_by: user, completed_at: Time.current)
  end

  def uncomplete!
    update!(done: false, completed_by: nil, completed_at: nil)
  end
end
