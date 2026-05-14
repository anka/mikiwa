class AttendancesController < ApplicationController
  before_action :require_staff!

  def index
    @date     = parse_date(params[:date]) || Date.current
    @group_id = params[:group_id]
    @groups   = Group.order(:name)
    @group    = Group.find_by(id: @group_id) if @group_id.present?

    if @group
      @children = Child.active.where(group: @group).order(:last_name, :first_name)
      existing = Attendance.for_date(@date).for_group(@group.id).index_by(&:child_id)
      @attendances_by_child = @children.index_with do |child|
        existing[child.id] || Attendance.new(
          child:             child,
          group:             @group,
          kindergarten_year: active_kindergarten_year,
          date:              @date,
          present:           true,
          recorded_by:       current_user
        )
      end
    end
  end

  def create
    date     = parse_date(params[:date]) || Date.current
    group    = Group.find(params[:group_id])
    submitted = params.fetch(:attendances, {}).to_unsafe_h

    Attendance.transaction do
      submitted.each do |child_id, attrs|
        record = Attendance.find_or_initialize_by(child_id: child_id, date: date)
        record.assign_attributes(
          group:             group,
          kindergarten_year: active_kindergarten_year,
          recorded_by:       current_user,
          present:           ActiveModel::Type::Boolean.new.cast(attrs["present"]) == true,
          absence_reason:    attrs["absence_reason"].presence,
          note:              attrs["note"].to_s.strip.presence
        )
        record.absence_reason = nil if record.present
        record.save!
      end
    end

    redirect_to attendances_path(date: date.to_fs(:iso8601), group_id: group.id),
                notice: "Anwesenheit gespeichert."
  end

  def update
    attendance = Attendance.find(params[:id])
    attendance.assign_attributes(attendance_params)
    attendance.absence_reason = nil if attendance.present
    attendance.recorded_by = current_user
    if attendance.save
      redirect_to attendances_path(date: attendance.date.to_fs(:iso8601), group_id: attendance.group_id),
                  notice: "Eintrag aktualisiert."
    else
      redirect_to attendances_path(date: attendance.date.to_fs(:iso8601), group_id: attendance.group_id),
                  alert: attendance.errors.full_messages.to_sentence
    end
  end

  private

  def attendance_params
    params.require(:attendance).permit(:present, :absence_reason, :note)
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
