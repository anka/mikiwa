class Posteingang < ApplicationRecord
  include UuidPrimaryKey

  self.table_name = "posteingaenge"

  belongs_to :mitteilung
  belongs_to :user

  validates :mitteilung_id, uniqueness: { scope: :user_id }

  scope :unread,  -> { where(read_at: nil) }
  scope :ordered, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
