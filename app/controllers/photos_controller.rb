class PhotosController < ApplicationController
  before_action :set_gallery
  before_action :require_staff!

  def update
    photo = @gallery.photos.find(params[:id])

    if photo.update(photo_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(view_context.dom_id(photo, :caption), partial: "galleries/photo_caption_field", locals: { gallery: @gallery, photo: photo }) }
        format.html { head :ok }
        format.json { render json: { ok: true, caption: photo.caption } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(view_context.dom_id(photo, :caption), partial: "galleries/photo_caption_field", locals: { gallery: @gallery, photo: photo }), status: :unprocessable_entity }
        format.html { head :unprocessable_entity }
        format.json { render json: { errors: photo.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

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

  def photo_params
    params.require(:photo).permit(:caption)
  end

  def set_gallery
    @gallery = Gallery.find(params[:gallery_id])
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
