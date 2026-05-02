class NotfallkontakteController < ApplicationController
  before_action :set_kind
  before_action :authorize_kind_access!
  before_action :set_notfallkontakt, only: %i[edit update destroy]

  def new
    @notfallkontakt = @kind.notfallkontakte.build(position: next_position)
  end

  def create
    @notfallkontakt = @kind.notfallkontakte.build(notfallkontakt_params)
    if @notfallkontakt.save
      redirect_to kinder_path(@kind), notice: "Notfallkontakt wurde hinzugefügt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @notfallkontakt.update(notfallkontakt_params)
      redirect_to kinder_path(@kind), notice: "Notfallkontakt wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notfallkontakt.destroy!
    redirect_to kinder_path(@kind), notice: "Notfallkontakt wurde gelöscht."
  end

  private

  def set_kind
    @kind = Kind.find(params[:kinder_id])
  end

  def authorize_kind_access!
    return if current_user&.staff?
    return if current_user.kinder.exists?(@kind.id)
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def set_notfallkontakt
    @notfallkontakt = @kind.notfallkontakte.find(params[:id])
  end

  def notfallkontakt_params
    params.require(:notfallkontakt).permit(:name, :beziehung, :telefon, :position)
  end

  def next_position
    (@kind.notfallkontakte.maximum(:position) || 0) + 1
  end
end
