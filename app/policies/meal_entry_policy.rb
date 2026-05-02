class MealEntryPolicy < ApplicationPolicy
  def index?  = user.present?
  def show?   = user.present?
  def new?    = staff?
  def create? = staff?
  def edit?   = staff?
  def update? = staff?
  def destroy? = staff?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.staff?
        scope.all
      else
        group_ids = user.children.active.pluck(:group_id).uniq
        scope.where(group_id: group_ids)
      end
    end
  end
end
