class MedicalNotesController < ApplicationController
  before_action :set_child
  before_action :authorize_child_access!
  before_action :set_medical_note, only: %i[edit update destroy]

  def new
    @medical_note = @child.medical_notes.build
  end

  def create
    @medical_note = @child.medical_notes.build(medical_note_params)
    if @medical_note.save
      redirect_to child_path(@child), notice: "Medizinischer Hinweis wurde hinzugefügt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @medical_note.update(medical_note_params)
      redirect_to child_path(@child), notice: "Medizinischer Hinweis wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medical_note.destroy!
    redirect_to child_path(@child), notice: "Medizinischer Hinweis wurde gelöscht."
  end

  private

  def set_child
    @child = Child.find(params[:child_id])
  end

  def authorize_child_access!
    return if current_user&.staff?
    return if current_user.children.exists?(@child.id)
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def set_medical_note
    @medical_note = @child.medical_notes.find(params[:id])
  end

  def medical_note_params
    params.require(:medical_note).permit(:note_type, :content)
  end
end
