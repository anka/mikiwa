class MitteilungGroup < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :mitteilung
  belongs_to :group
end
