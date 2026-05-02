class KinderController < ApplicationController
  before_action :set_kind, only: %i[edit update deaktivieren]
  before_action :require_staff_for_mutations!, only: %i[new create edit update deaktivieren]

  def index
    @kinder = scoped_kinder.active.includes(:gruppe, :eltern).order(:nachname, :vorname)
  end

  def new
    @kind = Kind.new(kindergartenjahr: aktives_jahr)
  end

  def create
    @kind = Kind.new(kind_params)
    if @kind.save
      verknuepfe_eltern(@kind)
      redirect_to kinder_index_path, notice: "#{@kind.vollstaendiger_name} wurde angelegt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @kind.update(kind_params)
      redirect_to kinder_index_path, notice: "Stammdaten wurden aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def deaktivieren
    @kind.deaktivieren!
    redirect_to kinder_index_path, notice: "#{@kind.vollstaendiger_name} wurde deaktiviert."
  end

  private

  def set_kind
    @kind = Kind.find(params[:id])
  end

  def kind_params
    params.require(:kind).permit(
      :vorname, :nachname, :rufname, :geburtsdatum,
      :gruppe_id, :kindergartenjahr_id, :foto_einwilligung, :profilfoto
    )
  end

  def require_staff_for_mutations!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def scoped_kinder
    return Kind.all if current_user&.staff?
    current_user.kinder
  end

  def aktives_jahr
    Kindergartenjahr.find_by(aktiv: true)
  end

  def verknuepfe_eltern(kind)
    eltern_id = params.dig(:kind, :eltern_id)
    return unless eltern_id.present?
    elternteil = User.find_by(id: eltern_id, role: "parent")
    ElternKind.create!(user: elternteil, kind: kind) if elternteil
  end
end
