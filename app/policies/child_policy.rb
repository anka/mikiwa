class ChildPolicy < ApplicationPolicy
  def index?    = true
  def show?     = staff? || parent_of_record?
  def new?      = staff?
  def create?   = staff?
  def edit?     = staff? || parent_of_record?
  def update?   = staff? || parent_of_record?
  def destroy?  = admin?

  def deactivate?     = staff?
  def update_consent? = staff? || parent_of_record?

  def manage_parents? = staff?
  alias_method :attach_parent?, :manage_parents?
  alias_method :detach_parent?, :manage_parents?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.staff?
      scope.joins(:parent_children).where(parent_children: { user_id: user&.id }).distinct
    end
  end

  private

  def parent_of_record?
    return false unless user&.parent? && record.respond_to?(:id)
    user.children.exists?(id: record.id)
  end
end
