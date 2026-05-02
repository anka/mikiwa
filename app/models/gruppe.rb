class Gruppe < ApplicationRecord
  self.table_name = "gruppen"

  has_many :kinder, class_name: "Kind", dependent: :nullify

  validates :name, presence: true
end
