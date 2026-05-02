class KindergartenjahreController < ApplicationController
  before_action :require_staff!
  before_action :set_kindergartenjahr, only: %i[edit update destroy aktiviere jahresubergang jahresubergang_durchfuehren]

  def index
    @kindergartenjahre = Kindergartenjahr.order(start_datum: :desc)
  end

  def new
    @kindergartenjahr = Kindergartenjahr.new
  end

  def create
    @kindergartenjahr = Kindergartenjahr.new(kindergartenjahr_params)
    if @kindergartenjahr.save
      redirect_to kindergartenjahre_index_path, notice: "Kindergartenjahr wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @kindergartenjahr.update(kindergartenjahr_params)
      redirect_to kindergartenjahre_index_path, notice: "Kindergartenjahr wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @kindergartenjahr.destroy
    redirect_to kindergartenjahre_index_path, notice: "Kindergartenjahr wurde gelöscht."
  end

  def aktiviere
    @kindergartenjahr.update!(aktiv: true)
    redirect_to kindergartenjahre_index_path, notice: "#{@kindergartenjahr.bezeichnung} ist jetzt das aktive Jahr."
  end

  def jahresubergang
    @kinder = aktive_kinder_des_vorjahres
  end

  def jahresubergang_durchfuehren
    kinder_ids = Array(params[:kind_ids])
    KindergartenjahresUebergang.new(@kindergartenjahr).durchfuehren(kinder_ids)
    @kindergartenjahr.update!(aktiv: true)
    redirect_to kindergartenjahre_index_path, notice: "Jahresübergang abgeschlossen. #{kinder_ids.size} Kind(er) übernommen."
  end

  private

  def set_kindergartenjahr
    @kindergartenjahr = Kindergartenjahr.find(params[:id])
  end

  def kindergartenjahr_params
    params.require(:kindergartenjahr).permit(:bezeichnung, :start_datum, :end_datum, :aktiv)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def aktive_kinder_des_vorjahres
    aktives = Kindergartenjahr.find_by(aktiv: true)
    return [] unless aktives
    aktives.kinder.active
  rescue NoMethodError
    []
  end
end
