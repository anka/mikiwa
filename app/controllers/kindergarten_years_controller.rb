class KindergartenYearsController < ApplicationController
  before_action :require_staff!
  before_action :set_kindergarten_year, only: %i[edit update destroy activate rollover execute_rollover]

  def index
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def new
    @kindergarten_year = KindergartenYear.new
  end

  def create
    @kindergarten_year = KindergartenYear.new(kindergarten_year_params)
    if @kindergarten_year.save
      redirect_to kindergarten_years_path, notice: "Kindergartenjahr wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @kindergarten_year.update(kindergarten_year_params)
      redirect_to kindergarten_years_path, notice: "Kindergartenjahr wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @kindergarten_year.destroy
    redirect_to kindergarten_years_path, notice: "Kindergartenjahr wurde gelöscht."
  end

  def activate
    @kindergarten_year.update!(active: true)
    redirect_to kindergarten_years_path, notice: "#{@kindergarten_year.label} ist jetzt das aktive Jahr."
  end

  def rollover
    @children = active_children_of_current_year
  end

  def execute_rollover
    child_ids = Array(params[:child_ids])
    KindergartenYearRollover.new(@kindergarten_year).execute(child_ids)
    @kindergarten_year.update!(active: true)
    redirect_to kindergarten_years_path, notice: "Jahresübergang abgeschlossen. #{child_ids.size} Kind(er) übernommen."
  end

  private

  def set_kindergarten_year
    @kindergarten_year = KindergartenYear.find(params[:id])
  end

  def kindergarten_year_params
    params.require(:kindergarten_year).permit(:label, :start_date, :end_date, :active)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def active_children_of_current_year
    active = KindergartenYear.find_by(active: true)
    return [] unless active
    active.children.active
  rescue NoMethodError
    []
  end
end
