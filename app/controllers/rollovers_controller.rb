class RolloversController < ApplicationController
  before_action :require_staff!

  def new
    @source_year = resolved_source_year
    @target_years = KindergartenYear.where(status: "planning").order(:start_date)
    @target_year_id = params[:target_year_id] || @target_years.first&.id

    children = @source_year&.children&.active || Child.none
    @children = children.search_by_name(params[:q])
                        .in_group(params[:group_id])
                        .with_age(params[:age])
                        .includes(:group)
                        .order(:last_name, :first_name)
    @all_active_ids = children.pluck(:id)

    @selected_ids = if params[:child_ids].is_a?(Array)
                      Array(params[:child_ids]).compact_blank
    else
                      @all_active_ids
    end

    @filter_q = params[:q].to_s
    @filter_group_id = params[:group_id]
    @filter_age = params[:age]
    @filter_groups = Group.order(:name)
    @filter_ages = filter_age_options(children)
  end

  def confirm
    @source_year = KindergartenYear.find_by(id: params[:source_year_id]) || KindergartenYear.active
    @target_year = KindergartenYear.find_by(id: params[:target_year_id])
    @selected_ids = Array(params[:child_ids]).compact_blank

    return redirect_to_new_with_alert("Bitte ein gültiges Zieljahr wählen.") unless @target_year
    return redirect_to_new_with_alert("Mindestens ein Kind muss ausgewählt sein.") if @selected_ids.empty?

    @to_transfer  = Child.where(id: @selected_ids).order(:last_name, :first_name)
    @to_deactivate = @source_year.children.active.where.not(id: @selected_ids).order(:last_name, :first_name)
  end

  def execute
    @source_year = KindergartenYear.find_by(id: params[:source_year_id]) || KindergartenYear.active
    @target_year = KindergartenYear.find_by(id: params[:target_year_id])
    selected_ids = Array(params[:child_ids]).compact_blank

    return redirect_to_new_with_alert("Bitte ein gültiges Zieljahr wählen.") unless @target_year

    transferred = 0
    deactivated = 0
    begin
      ActiveRecord::Base.transaction do
        Child.where(id: selected_ids).find_each do |c|
          c.transfer_to(@target_year)
          transferred += 1
        end
        @source_year.children.active.where.not(id: selected_ids).find_each do |c|
          c.deactivate!
          deactivated += 1
        end
      end
    rescue StandardError => e
      flash[:alert] = "Rollover fehlgeschlagen: #{e.message}"
      return redirect_to rollover_path
    end

    redirect_to children_path,
                notice: "Rollover abgeschlossen: #{transferred} übernommen, #{deactivated} deaktiviert."
  end

  private

  def resolved_source_year
    if params[:source_year_id].present?
      KindergartenYear.find_by(id: params[:source_year_id])
    else
      KindergartenYear.active
    end
  end

  def filter_age_options(children)
    children.pluck(:date_of_birth).filter_map do |dob|
      today = Date.current
      years = today.year - dob.year - (today.strftime("%m%d") < dob.strftime("%m%d") ? 1 : 0)
      years if years >= 0
    end.uniq.sort
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def redirect_to_new_with_alert(message)
    redirect_to rollover_path, alert: message
  end
end
