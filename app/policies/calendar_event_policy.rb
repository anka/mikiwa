class CalendarEventPolicy < ApplicationPolicy
  def index?  = true
  def show?   = staff? || parent_can_view?
  def new?    = staff?
  def create? = staff?
  def edit?   = staff?
  def update? = staff?
  def destroy? = staff?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.staff?

      group_ids = user.children.active.pluck(:group_id)
      scope.for_groups(group_ids)
    end
  end

  private

  def parent_can_view?
    return false unless user&.parent?
    user_group_ids = user.children.active.pluck(:group_id)
    (record.groups.pluck(:id) & user_group_ids).any?
  end
end
