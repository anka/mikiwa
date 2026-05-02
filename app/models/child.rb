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

  private

  def touch_photo_consent_timestamp
    self.photo_consent_updated_at = Time.current
  end

  public

  def display_name
    nickname.presence || first_name
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
    return if Child.where(last_name: last_name, first_name: first_name, date_of_birth: date_of_birth,
                          kindergarten_year_id: new_year.id).exists?

    new_child = dup
    new_child.kindergarten_year = new_year
    new_child.active = true
    new_child.save!

    parent_children.find_each do |pc|
      ParentChild.create!(user_id: pc.user_id, child_id: new_child.id, note: pc.note)
    end

    emergency_contacts.find_each do |ec|
      new_child.emergency_contacts.create!(
        name: ec.name, relationship: ec.relationship, phone: ec.phone, position: ec.position
      )
    end

    medical_notes.find_each do |mn|
      new_child.medical_notes.create!(note_type: mn.note_type, content: mn.content)
    end

    new_child
  end
end
