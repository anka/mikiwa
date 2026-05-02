class MessageGroup < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :message
  belongs_to :group
end
