class Child < ApplicationRecord
  include ImageAttachable

  belongs_to :group
  belongs_to :kindergarten_year
  has_many :parent_children, class_name: "ParentChild", foreign_key: "child_id", dependent: :destroy
  has_many :parents, through: :parent_children, source: :user
  has_many :emergency_contacts, class_name: "EmergencyContact", dependent: :destroy
  has_many :medical_notes, class_name: "MedicalNote", dependent: :destroy
  has_one_attached :profile_photo

  encrypts :insurance_number

  validates_image_attachment :profile_photo

  PHOTO_CONSENT_OPTIONS = [ true, false ].freeze

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :group, presence: true
  validates :kindergarten_year, presence: true
  validates :photo_consent, inclusion: { in: PHOTO_CONSENT_OPTIONS, message: "muss angegeben werden" }

  before_save :touch_photo_consent_timestamp, if: :photo_consent_changed?

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  scope :search_by_name, ->(query) {
    return all if query.blank?
    normalized = query.to_s.downcase.strip
    where(
      "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q",
      q: "%#{normalized}%"
    )
  }

  scope :in_group, ->(group_id) {
    return all if group_id.blank?
    where(group_id: group_id)
  }

  scope :with_age, ->(age) {
    return all if age.blank?
    today = Date.current
    age_int = age.to_i
    upper = today - age_int.years
    lower = today - (age_int + 1).years + 1.day
    where(date_of_birth: lower..upper)
  }

  private

  def touch_photo_consent_timestamp
    self.photo_consent_updated_at = Time.current
  end

  public

  def display_name
    nickname.presence || first_name
  end

  def age
    return nil if date_of_birth.blank?

    today = Date.current
    years = today.year - date_of_birth.year
    years -= 1 if today.strftime("%m%d") < date_of_birth.strftime("%m%d")
    years
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def update_consent!(value)
    update!(photo_consent: value)
  end

  def deactivate!
    update!(active: false)
  end

  def transfer_to(new_year)
    return self if kindergarten_year_id == new_year.id
    update!(kindergarten_year: new_year, active: true)
    self
  end
end
