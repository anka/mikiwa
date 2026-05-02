class GalleryGroup < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :gallery
  belongs_to :group
end
