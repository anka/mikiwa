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
      validates attribute, content_type: {
        in: ALLOWED_TYPES,
        message: "muss JPEG, PNG, HEIC oder WebP sein"
      }, size: {
        less_than: MAX_SIZE_BYTES,
        message: "darf maximal 15 MB groß sein"
      }, if: -> { send(attribute).attached? }
    end
  end
end
