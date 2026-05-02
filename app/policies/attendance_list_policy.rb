class AttendanceListPolicy < ApplicationPolicy
  def index?  = true
  def show?   = staff? || parent_in_group?
  def new?    = staff?
  def create? = staff?
  def edit?   = staff?
  def update? = staff?
  def destroy? = staff?
  def export? = staff?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.staff?

      group_ids = user.children.active.pluck(:group_id)
      scope.where(group_id: group_ids)
    end
  end

  private

  def parent_in_group?
    return false unless user&.parent?
    user.children.active.pluck(:group_id).include?(record.group_id)
  end
end
