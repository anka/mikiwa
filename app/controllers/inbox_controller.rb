class InboxController < ApplicationController
  def index
    @entries = InboxEntry.where(user: current_user)
                         .includes(message: :groups)
                         .ordered
  end

  def show
    @message = Message.find(params[:id])
    authorize!(@message, policy_class: MessagePolicy)
    @entry = InboxEntry.find_by(message: @message, user: current_user)
    @entry&.mark_as_read!
  end
end
