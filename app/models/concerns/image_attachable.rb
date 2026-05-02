module ImageAttachable
  extend ActiveSupport::Concern

  ALLOWED_TYPES = %w[image/jpeg image/png image/webp image/heic image/heif].freeze
  MAX_SIZE_BYTES = 15.megabytes

  VARIANT_CONFIGS = {
    thumb:   { resize_to_limit: [ 300, 300 ], format: :webp, saver: { quality: 85 } },
    display: { resize_to_limit: [ 1600, 1600 ], format: :webp, saver: { quality: 80 } },
    original: { resize_to_limit: [ 4000, 4000 ], strip: true }
  }.freeze

  included do
    def self.validates_image_attachment(attribute)
      validate do |record|
        attachment = record.send(attribute)
        next unless attachment.attached?

        unless ALLOWED_TYPES.include?(attachment.content_type)
          record.errors.add(attribute, "muss JPEG, PNG, HEIC oder WebP sein")
        end

        if attachment.byte_size > MAX_SIZE_BYTES
          record.errors.add(attribute, "darf maximal 15 MB groß sein")
        end
      end
    end
  end
end
