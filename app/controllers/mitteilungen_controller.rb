class MitteilungenController < ApplicationController
  before_action :require_staff!

  def index
    @messages = Mitteilung.includes(:groups).ordered
  end

  def new
    @message = Mitteilung.new
    @groups = Group.order(:name)
  end

  def create
    @message = Mitteilung.new(message_params)
    @message.sent_by = current_user
    assign_groups

    if @message.save
      @message.deliver!
      redirect_to mitteilungen_path, notice: "Mitteilung wurde versandt."
    else
      @groups = Group.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @message = Mitteilung.find(params[:id])
    @message.destroy
    redirect_to mitteilungen_path, notice: "Mitteilung wurde gelöscht."
  end

  private

  def message_params
    params.require(:mitteilung).permit(:title, :body, :attachment)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def assign_groups
    group_ids = Array(params.dig(:mitteilung, :group_ids)).reject(&:blank?)
    group_ids.each { |gid| @message.mitteilung_groups.build(group_id: gid) }
  end
end
