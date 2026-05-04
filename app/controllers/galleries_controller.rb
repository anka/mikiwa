class GalleriesController < ApplicationController
  before_action :set_gallery,     only: %i[show edit update destroy add_photo remove_photo download]
  before_action :require_staff!,  only: %i[new create edit update destroy add_photo remove_photo]

  def index
    @galleries = policy_scope(Gallery).includes(:groups, :created_by).ordered
  end

  def show
    authorize!(@gallery, policy_class: GalleryPolicy)
    @photos = @gallery.photos.order(:created_at)
    @consent_warnings = @gallery.groups.flat_map { |g| @gallery.consent_warnings(g).to_a }.uniq
  end

  def new
    @gallery = Gallery.new(kindergarten_year: active_kindergarten_year)
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
    @events = Event.order(:start_date)
  end

  def create
    @gallery = Gallery.new(gallery_params)
    @gallery.created_by = current_user
    submitted_group_ids.each { |gid| @gallery.gallery_groups.build(group_id: gid) }

    if @gallery.save
      handle_photo_uploads if params[:gallery][:photos].present?
      redirect_to gallery_path(@gallery), notice: "Galerie wurde angelegt."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      @events = Event.order(:start_date)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
    @events = Event.order(:start_date)
  end

  def update
    saved = false
    new_group_ids = submitted_group_ids
    @gallery.transaction do
      @gallery.assign_attributes(gallery_params)
      @gallery.group_ids = new_group_ids
      saved = @gallery.save
      raise ActiveRecord::Rollback unless saved
    end

    if saved
      handle_photo_uploads if params[:gallery][:photos].present?
      redirect_to gallery_path(@gallery), notice: "Galerie wurde aktualisiert."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      @events = Event.order(:start_date)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @gallery.destroy
    redirect_to galleries_path, notice: "Galerie wurde gelöscht."
  end

  def add_photo
    authorize!(@gallery, policy_class: GalleryPolicy)
    photo = params[:photo]

    if photo.blank? || !photo.respond_to?(:content_type)
      render json: { error: "Keine Datei übermittelt." }, status: :unprocessable_entity
      return
    end

    unless ImageAttachable::ALLOWED_TYPES.include?(photo.content_type)
      render json: { error: "#{photo.original_filename}: Format nicht erlaubt (JPEG, PNG, HEIC, WebP)." },
             status: :unprocessable_entity
      return
    end

    if photo.size > ImageAttachable::MAX_SIZE_BYTES
      render json: { error: "#{photo.original_filename}: zu groß (max. #{ImageAttachable::MAX_SIZE_MB} MB)." },
             status: :unprocessable_entity
      return
    end

    @gallery.photos.attach(photo)
    render json: { ok: true, filename: photo.original_filename }
  end

  def remove_photo
    authorize!(@gallery, policy_class: GalleryPolicy)
    attachment = @gallery.photos.attachments.find(params[:photo_id])
    attachment.purge
    redirect_to gallery_path(@gallery), notice: "Bild wurde entfernt."
  end

  def download
    authorize!(@gallery, policy_class: GalleryPolicy)
    attachment = @gallery.photos.attachments.find(params[:photo_id])
    redirect_to rails_blob_url(attachment.blob, disposition: "attachment", expires_in: 1.hour),
                allow_other_host: true
  end

  private

  def set_gallery
    @gallery = Gallery.find(params[:id])
  end

  def gallery_params
    params.require(:gallery).permit(:title, :description, :event_date, :kindergarten_year_id, :event_id)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def submitted_group_ids
    Array(params.dig(:gallery, :group_ids)).reject(&:blank?)
  end

  def handle_photo_uploads
    Array(params[:gallery][:photos]).each do |photo|
      next unless photo.respond_to?(:content_type)
      @gallery.photos.attach(photo)
    end
  end
end
