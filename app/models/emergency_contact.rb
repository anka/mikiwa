class EmergencyContact < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :child
  belongs_to :user, optional: true

  encrypts :name
  encrypts :phone

  validates :relationship, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :name,  presence: true, if: -> { user_id.blank? }
  validates :phone, presence: true, if: -> { user_id.blank? }
  validate  :user_must_be_parent_of_child, if: -> { user_id.present? }

  default_scope { order(:position) }

  def display_name
    user&.full_name.presence || name
  end

  def display_phone
    user&.phone.presence || phone
  end

  def linked?
    user_id.present?
  end

  private

  def user_must_be_parent_of_child
    return if child.nil? || user.nil?
    unless child.parents.exists?(user_id)
      errors.add(:user, "ist nicht als Elternteil dieses Kindes verknüpft")
    end
  end
end
