class MealEntriesController < ApplicationController
  before_action :set_meal_entry, only: %i[edit update destroy]
  before_action :require_staff!, only: %i[new create edit update destroy export]

  EXPORT_MAX_SPAN_DAYS = 92

  def index
    week_date    = params[:week].present? ? Date.parse(params[:week]) : Date.current
    @week_start  = week_date.beginning_of_week(:monday)
    @week_days   = (0..4).map { |d| @week_start + d.days }

    @groups = if current_user.staff?
      Group.order(:name)
    else
      group_ids = current_user.children.active.pluck(:group_id).uniq
      Group.where(id: group_ids).order(:name)
    end

    entries = MealEntry.for_week(@week_start)
                       .where(group: @groups)
                       .includes(:meal_courses)
    @entries_by_day_group = entries.index_by { |e| [ e.date, e.group_id ] }
  end

  # F33: Druckbare Wochenansicht pro Gruppe (A4 Querformat)
  def print
    @group = Group.find_by(id: params[:group_id])
    raise ActionController::RoutingError, "Group not found" unless @group
    raise ApplicationPolicy::NotAuthorizedError unless visible_groups.exists?(id: @group.id)

    week_date    = params[:week].present? ? Date.parse(params[:week]) : Date.current
    @week_start  = week_date.beginning_of_week(:monday)
    @week_days   = (0..4).map { |d| @week_start + d.days }
    @week_number = @week_start.cweek

    @entries_by_day = MealEntry.for_week(@week_start)
                               .where(group: @group)
                               .includes(:meal_courses)
                               .index_by(&:date)

    render layout: "print"
  end

  # F62: Excel-Export Form (HTML) und Excel-Generierung (xlsx).
  # Trennung via Format: HTML → Form, xlsx → Validate + Render Workbook.
  def export
    @groups = Group.order(:name)
    @start_date = parse_export_date(params[:start_date])
    @end_date   = parse_export_date(params[:end_date])
    @group_id   = params[:group_id]

    respond_to do |format|
      format.html
      format.xlsx do
        @errors = export_validation_errors(@start_date, @end_date, @group_id)
        if @errors.any?
          render :export, formats: :html, status: :unprocessable_entity
          return
        end

        @group       = Group.find(@group_id)
        @days        = (@start_date..@end_date).to_a
        @entries_by_date = MealEntry.where(date: @days, group: @group)
                                    .includes(:meal_courses)
                                    .index_by(&:date)
        response.headers["Content-Disposition"] = %(attachment; filename="#{
          helpers.export_filename('speiseplan',
                                  @group.name.parameterize,
                                  @start_date.to_fs(:iso8601),
                                  @end_date.to_fs(:iso8601))
        }")
      end
    end
  end

  def new
    @meal_entry = MealEntry.new(
      date: params[:date].present? ? Date.parse(params[:date]) : Date.current,
      group_id: params[:group_id],
      kindergarten_year: active_kindergarten_year
    )
    load_form_collections
  end

  def create
    @meal_entry = MealEntry.new(meal_entry_params)
    @meal_entry.created_by = current_user

    if @meal_entry.save
      redirect_to meal_entries_path(week: @meal_entry.date.iso8601),
                  notice: "Speiseplan-Eintrag wurde gespeichert."
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_collections
  end

  def update
    if @meal_entry.update(meal_entry_params)
      redirect_to meal_entries_path(week: @meal_entry.date.iso8601),
                  notice: "Speiseplan-Eintrag wurde aktualisiert."
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    week = @meal_entry.date.iso8601
    @meal_entry.destroy
    redirect_to meal_entries_path(week: week),
                notice: "Speiseplan-Eintrag wurde gelöscht."
  end

  private

  def set_meal_entry
    @meal_entry = MealEntry.find(params[:id])
  end

  def meal_entry_params
    params.require(:meal_entry).permit(
      :date, :notes, :group_id, :kindergarten_year_id,
      meal_courses_attributes: [ :id, :course_type, :name, :dietary, :position, :_destroy ]
    )
  end

  def load_form_collections
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def parse_export_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def export_validation_errors(start_date, end_date, group_id)
    errors = []
    errors << "Startdatum fehlt"             if start_date.nil?
    errors << "Enddatum fehlt"               if end_date.nil?
    errors << "Gruppe muss ausgewählt sein"  if group_id.blank?
    return errors if errors.any?

    if end_date < start_date
      errors << "Ende muss nach Start liegen"
    elsif (end_date - start_date).to_i + 1 > EXPORT_MAX_SPAN_DAYS
      errors << "Zeitraum max. #{EXPORT_MAX_SPAN_DAYS} Tage"
    end

    errors << "Gruppe nicht gefunden" if group_id.present? && !Group.exists?(id: group_id)
    errors
  end

  def visible_groups
    if current_user&.staff?
      Group.all
    elsif current_user
      Group.where(id: current_user.children.active.pluck(:group_id).uniq)
    else
      Group.none
    end
  end
end
