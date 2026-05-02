class AttendanceEntriesController < ApplicationController
  before_action :set_list
  before_action :set_entry, only: %i[destroy]

  def create
    if @list.deadline_passed?
      render plain: "Anmeldeschluss überschritten", status: :unprocessable_entity
      return
    end

    @entry = @list.attendance_entries.build(entry_params)
    @entry.user = current_user

    unless entry_belongs_to_current_user?(@entry.child_id)
      render plain: "Zugriff verweigert", status: :forbidden
      return
    end

    if @entry.save
      redirect_to attendance_list_path(@list), notice: "Eintrag wurde gespeichert."
    else
      redirect_to attendance_list_path(@list), alert: @entry.errors.full_messages.first
    end
  end

  def destroy
    if @list.deadline_passed?
      render plain: "Anmeldeschluss überschritten", status: :unprocessable_entity
      return
    end

    unless current_user.staff? || @entry.user_id == current_user.id
      render plain: "Zugriff verweigert", status: :forbidden
      return
    end

    @entry.destroy
    redirect_to attendance_list_path(@list), notice: "Eintrag wurde zurückgenommen."
  end

  private

  def set_list
    @list = AttendanceList.find(params[:attendance_list_id])
  end

  def set_entry
    @entry = @list.attendance_entries.find(params[:id])
  end

  def entry_params
    params.require(:attendance_entry).permit(:child_id)
  end

  def entry_belongs_to_current_user?(child_id)
    return true if current_user.staff?
    current_user.children.active.exists?(child_id)
  end
end
