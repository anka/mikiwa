require "csv"

class AttendanceListsController < ApplicationController
  before_action :set_list,     only: %i[show edit update destroy export]
  before_action :require_staff!, only: %i[new create edit update destroy export]

  def index
    @lists = policy_scope(AttendanceList).includes(:group, :attendance_entries).ordered
    @groups = Group.order(:name)
  end

  def show
    authorize!(@list, policy_class: AttendanceListPolicy)
    @entries = @list.attendance_entries.includes(:child, :user,
      attendance_date_selections: :attendance_date_option).ordered
    @date_options = @list.attendance_date_options.order(:date)
    @user_children = current_user.parent? ?
      current_user.children.active.where(group: @list.group) : []
  end

  def new
    @list = AttendanceList.new(kindergarten_year: active_kindergarten_year)
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def create
    @list = AttendanceList.new(list_params)
    @list.created_by = current_user

    if @list.save
      redirect_to attendance_list_path(@list), notice: "Teilnahmeliste wurde angelegt."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def update
    if @list.update(list_params)
      redirect_to attendance_list_path(@list), notice: "Liste wurde aktualisiert."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @list.destroy
    redirect_to attendance_lists_path, notice: "Liste wurde gelöscht."
  end

  def export
    entries = @list.attendance_entries.includes(:child,
      attendance_date_selections: :attendance_date_option).ordered
    date_options = @list.attendance_date_options.order(:date)

    csv_content = CSV.generate(col_sep: ";", encoding: "UTF-8") do |csv|
      if @list.mode == "per_date"
        header = [ "Name des Kindes", "Eingetragen am" ] + date_options.map { |d| l(d.date, format: :short) }
        csv << header
        entries.each do |entry|
          selected_ids = entry.attendance_date_selections.map(&:attendance_date_option_id).to_set
          row = [ entry.child.full_name, l(entry.created_at, format: :short) ]
          date_options.each { |d| row << (selected_ids.include?(d.id) ? "Ja" : "Nein") }
          csv << row
        end
      else
        csv << [ "Name des Kindes", "Eingetragen am" ]
        entries.each do |entry|
          csv << [ entry.child.full_name, l(entry.created_at, format: :short) ]
        end
      end
    end

    send_data "\xEF\xBB\xBF" + csv_content,
      filename: "teilnahmeliste-#{@list.id}.csv",
      type: "text/csv; charset=UTF-8",
      disposition: :attachment
  end

  private

  def set_list
    @list = AttendanceList.find(params[:id])
  end

  def list_params
    params.require(:attendance_list).permit(
      :title, :description, :mode, :deadline,
      :group_id, :kindergarten_year_id,
      attendance_date_options_attributes: [ :id, :date, :_destroy ]
    )
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
