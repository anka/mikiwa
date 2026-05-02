class Group < ApplicationRecord
  has_many :children, class_name: "Child", dependent: :nullify

  validates :name, presence: true
end
