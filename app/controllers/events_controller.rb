class EventsController < ApplicationController
  before_action :set_event,     only: %i[show edit update destroy cancel]
  before_action :require_staff!, only: %i[new create edit update destroy cancel]

  def index
    @current_year = active_kindergarten_year || KindergartenYear.order(start_date: :desc).first
    @filter_year  = params[:kindergarten_year_id].present? ?
      KindergartenYear.find_by(id: params[:kindergarten_year_id]) : @current_year
    @filter_year ||= @current_year

    base_scope = policy_scope(Event).for_year(@filter_year).includes(:groups).ordered
    base_scope = base_scope.for_groups([ params[:group_id] ]) if params[:group_id].present?

    @events = base_scope
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def show
    authorize!(@event, policy_class: EventPolicy)
  end

  def new
    @event = Event.new(kindergarten_year: active_kindergarten_year, all_day: false)
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
  end

  def create
    @event = Event.new(event_params)
    @event.created_by = current_user
    params.dig(:event, :group_ids).to_a.compact_blank.each do |gid|
      @event.calendar_event_groups.build(group_id: gid)
    end

    if @event.save
      redirect_to event_path(@event), notice: "Veranstaltung wurde angelegt."
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
    new_group_ids = params.dig(:event, :group_ids).to_a.compact_blank
    @event.calendar_event_groups.destroy_all
    new_group_ids.each { |gid| @event.calendar_event_groups.build(group_id: gid) }

    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Veranstaltung wurde aktualisiert."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      render :edit, status: :unprocessable_entity
    end
  end

  def cancel
    @event.cancel!
    redirect_to event_path(@event), notice: "Veranstaltung wurde abgesagt."
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Veranstaltung wurde gelöscht."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :title, :start_date, :all_day, :start_time,
      :location, :address, :description, :kindergarten_year_id
    )
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end
end
