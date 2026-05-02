class Vote < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :poll_option
  belongs_to :user

  validates :poll_option_id, uniqueness: { scope: :user_id }
end
