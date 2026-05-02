class EmergencyContactsController < ApplicationController
  before_action :set_child
  before_action :authorize_child_access!
  before_action :set_emergency_contact, only: %i[edit update destroy]

  def new
    @emergency_contact = @child.emergency_contacts.build(position: next_position)
  end

  def create
    @emergency_contact = @child.emergency_contacts.build(emergency_contact_params)
    if @emergency_contact.save
      redirect_to child_path(@child), notice: "Notfallkontakt wurde hinzugefügt."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @emergency_contact.update(emergency_contact_params)
      redirect_to child_path(@child), notice: "Notfallkontakt wurde aktualisiert."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @emergency_contact.destroy!
    redirect_to child_path(@child), notice: "Notfallkontakt wurde gelöscht."
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

  def set_emergency_contact
    @emergency_contact = @child.emergency_contacts.find(params[:id])
  end

  def emergency_contact_params
    params.require(:emergency_contact).permit(:name, :relationship, :phone, :position)
  end

  def next_position
    (@child.emergency_contacts.maximum(:position) || 0) + 1
  end
end
