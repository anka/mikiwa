class InboxEntry < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :message
  belongs_to :user

  validates :message_id, uniqueness: { scope: :user_id }

  scope :unread,  -> { where(read_at: nil) }
  scope :ordered, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
