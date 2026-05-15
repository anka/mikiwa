class Gallery < ApplicationRecord
  include UuidPrimaryKey
  include ImageAttachable

  MAX_PHOTOS = 200

  AUDIO_TYPES = %w[audio/mpeg audio/mp4 audio/x-m4a].freeze
  AUDIO_MAX_SIZE_BYTES = 25.megabytes
  AUDIO_MAX_SIZE_MB = AUDIO_MAX_SIZE_BYTES / 1.megabyte

  belongs_to :kindergarten_year
  belongs_to :created_by, class_name: "User"
  belongs_to :event, class_name: "Event", optional: true, foreign_key: :event_id

  has_many :gallery_groups, dependent: :destroy
  has_many :groups, through: :gallery_groups
  has_many :photos, -> { in_order }, dependent: :destroy

  has_one_attached :audio

  validates :title,             presence: true
  validates :kindergarten_year, presence: true
  validates :created_by,        presence: true
  validate  :at_least_one_group
  validate  :photos_within_limit
  validate  :audio_valid_type_and_size

  enum :visibility, { internal: 0, released: 1 }, default: :internal
  enum :slideshow_speed, { slow: "slow", normal: "normal", fast: "fast" },
       default: :normal, prefix: true

  scope :ordered,  -> { order(created_at: :desc) }
  scope :released, -> { where(visibility: :released) }

  def consent_warnings(group)
    group.children
         .where(kindergarten_year: kindergarten_year, photo_consent: false, active: true)
  end

  private

  def at_least_one_group
    active = gallery_groups.reject(&:marked_for_destruction?)
    errors.add(:gallery_groups, "mindestens eine Gruppe muss zugeordnet sein") if active.empty?
  end

  def photos_within_limit
    return unless photos.loaded? || persisted?
    if photos.count > MAX_PHOTOS
      errors.add(:photos, "maximal #{MAX_PHOTOS} Bilder pro Galerie erlaubt")
    end
  end

  def audio_valid_type_and_size
    return unless audio.attached?
    unless AUDIO_TYPES.include?(audio.content_type)
      errors.add(:audio, "muss MP3 oder M4A sein")
    end
    if audio.byte_size > AUDIO_MAX_SIZE_BYTES
      errors.add(:audio, "darf maximal #{AUDIO_MAX_SIZE_MB} MB groß sein")
    end
  end
end
