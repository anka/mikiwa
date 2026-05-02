require "csv"

class AbstimmungenController < ApplicationController
  before_action :set_poll,      only: %i[show edit update destroy vote close export]
  before_action :require_staff!, only: %i[new create edit update destroy close]

  def index
    @polls = policy_scope(Abstimmung).includes(:group, :abstimmung_optionen).ordered
  end

  def show
    authorize!(@poll, policy_class: AbstimmungPolicy)
    @results      = @poll.votes_by_option
    @user_options = @poll.stimmen.where(user: current_user).pluck(:abstimmung_option_id)
  end

  def new
    @poll = Abstimmung.new(kindergarten_year: active_year)
    2.times { @poll.abstimmung_optionen.build }
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
    @events = Event.order(:start_date)
  end

  def create
    @poll = Abstimmung.new(poll_params)
    @poll.created_by = current_user
    if @poll.save
      redirect_to abstimmung_path(@poll), notice: "Abstimmung wurde angelegt."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      @events = Event.order(:start_date)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @groups = Group.order(:name)
    @kindergarten_years = KindergartenYear.order(start_date: :desc)
    @events = Event.order(:start_date)
  end

  def update
    if @poll.update(poll_params)
      redirect_to abstimmung_path(@poll), notice: "Abstimmung wurde aktualisiert."
    else
      @groups = Group.order(:name)
      @kindergarten_years = KindergartenYear.order(start_date: :desc)
      @events = Event.order(:start_date)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @poll.destroy
    redirect_to abstimmungen_path, notice: "Abstimmung wurde gelöscht."
  end

  def vote
    authorize!(@poll, policy_class: AbstimmungPolicy)
    option_ids = Array(params[:option_ids]).reject(&:blank?)
    @poll.vote!(user: current_user, option_ids: option_ids)
    redirect_to abstimmung_path(@poll), notice: "Stimme wurde gespeichert."
  rescue Abstimmung::ClosedError
    render plain: "Abstimmung ist geschlossen.", status: :unprocessable_entity
  end

  def close
    authorize!(@poll, policy_class: AbstimmungPolicy)
    @poll.close!
    redirect_to abstimmung_path(@poll), notice: "Abstimmung wurde geschlossen."
  end

  def export
    authorize!(@poll, policy_class: AbstimmungPolicy)
    csv_data = build_csv
    send_data "\xEF\xBB\xBF" + csv_data,
              filename: "abstimmung_#{@poll.id}.csv",
              type: "text/csv; charset=utf-8",
              disposition: "attachment"
  end

  private

  def set_poll
    @poll = Abstimmung.find(params[:id])
  end

  def poll_params
    params.require(:abstimmung).permit(
      :title, :description, :poll_type, :deadline, :group_id,
      :kindergarten_year_id, :event_id,
      abstimmung_optionen_attributes: [ :id, :label, :position, :_destroy ]
    )
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def active_year
    KindergartenYear.find_by(active: true)
  end

  def build_csv
    CSV.generate(col_sep: ";") do |csv|
      csv << [ "Name", "Option(en)", "Zeitstempel" ]
      voters = @poll.stimmen.includes(:user, :abstimmung_option).order(:created_at)
      grouped = voters.group_by(&:user)
      grouped.each do |user, stimmen|
        options = stimmen.map { |s| s.abstimmung_option.label }.join(", ")
        timestamp = stimmen.map(&:created_at).max
        csv << [ user.full_name.presence || user.email, options, l(timestamp, format: :short) ]
      end
    end
  end
end
