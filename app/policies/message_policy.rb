class MessagePolicy < ApplicationPolicy
  def index?   = staff?
  def show?    = staff? || recipient?
  def new?     = staff?
  def create?  = staff?
  def destroy? = staff?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def recipient?
    return false unless user&.parent?
    InboxEntry.exists?(message: record, user: user)
  end
end
