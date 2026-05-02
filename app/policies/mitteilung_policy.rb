class MitteilungPolicy < ApplicationPolicy
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
    Posteingang.exists?(mitteilung: record, user: user)
  end
end
