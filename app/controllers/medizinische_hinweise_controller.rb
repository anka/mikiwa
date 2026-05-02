class MedizinischeHinweiseController < ApplicationController
  before_action :set_kind
  before_action :authorize_kind_access!
  before_action :set_medizinischer_hinweis, only: %i[edit update destroy]

  def new
    @medizinischer_hinweis = @kind.medizinische_hinweise.build
  end

  def create
    @medizinischer_hinweis = @kind.medizinische_hinweise.build(medizinischer_hinweis_params)
    if @medizinischer_hinweis.save
      redirect_to kinder_path(@kind), notice: "Medizinischer Hinweis wurde hinzugefügt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @medizinischer_hinweis.update(medizinischer_hinweis_params)
      redirect_to kinder_path(@kind), notice: "Medizinischer Hinweis wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medizinischer_hinweis.destroy!
    redirect_to kinder_path(@kind), notice: "Medizinischer Hinweis wurde gelöscht."
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

  def set_medizinischer_hinweis
    @medizinischer_hinweis = @kind.medizinische_hinweise.find(params[:id])
  end

  def medizinischer_hinweis_params
    params.require(:medizinischer_hinweis).permit(:hinweis_typ, :inhalt)
  end
end
