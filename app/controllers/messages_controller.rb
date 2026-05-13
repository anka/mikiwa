class MessagesController < ApplicationController
  before_action :require_staff!

  def index
    @messages = Message.includes(:groups).ordered
  end

  def show
    @message = Message.includes(:groups, :sent_by, :inbox_entries).find(params[:id])
  end

  def new
    @message = Message.new
    @groups = Group.order(:name)
  end

  def create
    @message = Message.new(message_params)
    @message.sent_by = current_user
    assign_groups

    if @message.save
      @message.deliver!
      redirect_to messages_path, notice: "Mitteilung wurde versandt."
    else
      @groups = Group.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy
    redirect_to messages_path, notice: "Mitteilung wurde gelöscht."
  end

  private

  def message_params
    params.require(:message).permit(:title, :body, :attachment)
  end

  def require_staff!
    return if current_user&.staff?
    render plain: "Zugriff verweigert", status: :forbidden
  end

  def assign_groups
    group_ids = Array(params.dig(:message, :group_ids)).reject(&:blank?)
    group_ids.each { |gid| @message.message_groups.build(group_id: gid) }
  end
end
