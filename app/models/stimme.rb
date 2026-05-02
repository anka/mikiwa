class Stimme < ApplicationRecord
  include UuidPrimaryKey

  self.table_name = "stimmen"

  belongs_to :abstimmung_option
  belongs_to :user

  validates :abstimmung_option_id, uniqueness: { scope: :user_id }
end
