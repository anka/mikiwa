class MealEntriesController < ApplicationController
  before_action :set_meal_entry, only: %i[edit update destroy]
  before_action :require_staff!, only: %i[new create edit update destroy]

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
