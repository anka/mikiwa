class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :invited_by, class_name: "User", optional: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  ROLES = %w[admin caretaker parent].freeze

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 16 }, allow_nil: true

  generates_token_for :magic_link, expires_in: 30.minutes do
    magic_link_token_version
  end

  scope :staff, -> { where(role: %w[admin caretaker]) }
  scope :active, -> { where(locked_at: nil) }
  scope :locked, -> { where.not(locked_at: nil) }

  def admin? = role == "admin"
  def caretaker? = role == "caretaker"
  def parent? = role == "parent"
  def staff? = admin? || caretaker?

  def locked? = locked_at.present?

  def lock!
    sessions.destroy_all
    update!(locked_at: Time.current)
  end

  def unlock!
    update!(locked_at: nil)
  end

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def invalidate_magic_link_token!
    increment!(:magic_link_token_version)
  end
end
