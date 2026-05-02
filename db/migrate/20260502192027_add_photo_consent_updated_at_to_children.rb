class AddPhotoConsentUpdatedAtToChildren < ActiveRecord::Migration[8.1]
  def change
    add_column :children, :photo_consent_updated_at, :datetime
  end
end
