class ElternKind < ApplicationRecord
  self.table_name = "eltern_kinder"
  belongs_to :user
  belongs_to :kind

  validates :user_id, uniqueness: { scope: :kind_id }
end
