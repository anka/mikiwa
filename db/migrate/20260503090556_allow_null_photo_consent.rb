class AllowNullPhotoConsent < ActiveRecord::Migration[8.1]
  def change
    change_column_null :children, :photo_consent, true
  end
end
