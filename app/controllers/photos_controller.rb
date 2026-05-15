class PhotosController < ApplicationController
  before_action :set_gallery
  before_action :require_staff!

  def destroy
    photo = @gallery.photos.find(params[:id])
    photo.destroy
    redirect_to gallery_path(@gallery), notice: "Bild wurde entfernt."
  end

  def reorder
    submitted_ids = Array(params[:photo_ids]).map(&:to_s)
    existing_ids  = @gallery.photos.pluck(:id)

    if submitted_ids.sort != existing_ids.sort
      render json: { error: "photo_ids unvollständig oder unbekannt" }, status: :unprocessable_entity
      return
    end

    Photo.transaction do
      submitted_ids.each_with_index do |id, idx|
        Photo.where(id: id, gallery_id: @gallery.id).update_all(position: idx + 1)
      end
    end

    head :ok
  end

  private

  def set_gallery
    @gallery = Gallery.find(params[:gallery_id])
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
