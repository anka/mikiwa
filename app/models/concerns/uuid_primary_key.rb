module UuidPrimaryKey
  extend ActiveSupport::Concern

  included do
    before_create do
      next unless self.class.primary_key.present?
      self.id = SecureRandom.uuid if id.blank?
    end
  end
end
