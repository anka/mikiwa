class ParentChild < ApplicationRecord
  belongs_to :user
  belongs_to :child

  validates :user_id, uniqueness: { scope: :child_id }
end
