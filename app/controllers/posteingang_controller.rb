class PosteingangController < ApplicationController
  def index
    @entries = Posteingang.where(user: current_user)
                          .includes(mitteilung: :groups)
                          .ordered
  end

  def show
    @mitteilung = Mitteilung.find(params[:id])
    authorize!(@mitteilung, policy_class: MitteilungPolicy)
    @entry = Posteingang.find_by(mitteilung: @mitteilung, user: current_user)
    @entry&.mark_as_read!
  end
end
