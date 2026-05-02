class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }

  ROLES = %w[admin caretaker parent].freeze

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 16 }, allow_nil: true

  generates_token_for :magic_link, expires_in: 30.minutes do
    magic_link_token_version
  end

  def admin? = role == "admin"
  def caretaker? = role == "caretaker"
  def parent? = role == "parent"
  def staff? = admin? || caretaker?

  def invalidate_magic_link_token!
    increment!(:magic_link_token_version)
  end
end
