class CalendarEventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]
  before_action :require_staff_for_mutations!, only: %i[new create edit update destroy]

  def index
    @view = params[:view] == "list" ? "list" : "month"
    @current_year = active_year || KindergartenYear.order(start_date: :desc).first
    @filter_year  = params[:kindergarten_year_id].present? ?
      KindergartenYear.find_by(id: params[:kindergarten_year_id]) : @current_year
    @filter_year ||= @current_year

    @groups = Group.order(:name)
    base_scope = policy_scope(CalendarEvent).for_year(@filter_year).includes(:groups)

    if params[:group_id].present?
      base_scope = base_scope.for_groups([ params[:group_id] ])
    end

    if @view == "month"
      @month = parse_month(params[:month])
      @events_by_date = base_scope.for_month(@month).ordered.group_by(&:start_date)
      @calendar_cells = build_calendar_cells(@month)
    else
      @events = base_scope.ordered
    end

    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def show
    authorize!(@event)
  end

  def new
    @event = CalendarEvent.new(kindergarten_year: active_year, all_day: true)
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def create
    @event = CalendarEvent.new(event_params)
    @event.created_by = current_user
    params.dig(:calendar_event, :group_ids).to_a.compact_blank.each do |gid|
      @event.calendar_event_groups.build(group_id: gid)
    end

    if @event.save
      redirect_to calendar_events_path, notice: "Ereignis wurde angelegt."
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
    new_group_ids = params.dig(:calendar_event, :group_ids).to_a.compact_blank
    @event.calendar_event_groups.destroy_all
    new_group_ids.each { |gid| @event.calendar_event_groups.build(group_id: gid) }
    if @event.update(event_params)
      redirect_to calendar_events_path, notice: "Ereignis wurde aktualisiert."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to calendar_events_path, notice: "Ereignis wurde gelöscht."
  end

  private

  def set_event
    @event = CalendarEvent.find(params[:id])
  end

  def event_params
    params.require(:calendar_event).permit(
      :title, :start_date, :all_day, :start_time,
      :location, :description, :kindergarten_year_id
    )
  end

  def require_staff_for_mutations!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def active_year
    KindergartenYear.find_by(active: true)
  end

  def parse_month(month_param)
    Date.parse("#{month_param}-01")
  rescue ArgumentError, TypeError
    Date.today.beginning_of_month
  end

  def build_calendar_cells(month)
    first = month.beginning_of_month
    last  = month.end_of_month
    # Monday-based week: pad start
    leading  = (first.wday - 1) % 7
    trailing = (7 - (last.wday % 7)) % 7
    cells = Array.new(leading, nil)
    cells += (first..last).to_a
    cells += Array.new(trailing, nil)
    cells
  end
end
