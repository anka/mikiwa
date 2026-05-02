class Gruppe < ApplicationRecord
  self.table_name = "gruppen"

  validates :name, presence: true
end
