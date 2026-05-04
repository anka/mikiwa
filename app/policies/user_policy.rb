class UserPolicy < ApplicationPolicy
  def index?   = staff?
  def show?    = staff?
  def new?     = staff?
  def create?  = staff?
  def edit?    = staff? && record_is_parent?
  def update?  = staff? && record_is_parent?
  def destroy? = admin? && record_is_parent?

  def lock?     = staff? && record_is_parent?
  def unlock?   = staff? && record_is_parent?
  def reinvite? = staff? && record_is_parent?

  private

  def record_is_parent?
    record.respond_to?(:parent?) && record.parent?
  end
end
