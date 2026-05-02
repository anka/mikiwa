class GruppenController < ApplicationController
  before_action :require_staff!
  before_action :set_gruppe, only: %i[edit update destroy]

  def index
    @gruppen = Gruppe.order(:name)
  end

  def new
    @gruppe = Gruppe.new
  end

  def create
    @gruppe = Gruppe.new(gruppe_params)
    if @gruppe.save
      redirect_to gruppen_index_path, notice: "Gruppe wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @gruppe.update(gruppe_params)
      redirect_to gruppen_index_path, notice: "Gruppe wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @gruppe.destroy
    redirect_to gruppen_index_path, notice: "Gruppe wurde gelöscht."
  end

  private

  def set_gruppe
    @gruppe = Gruppe.find(params[:id])
  end

  def gruppe_params
    params.require(:gruppe).permit(:name, :farbe, :beschreibung)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
