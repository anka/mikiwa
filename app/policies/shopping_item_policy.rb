class ShoppingItemPolicy < ApplicationPolicy
  def create?  = staff?
  def update?  = staff?
  def destroy? = staff?

  def complete?   = staff? || parent_in_group?
  def uncomplete? = staff? || parent_in_group?

  private

  def parent_in_group?
    return false unless user&.parent?
    user.children.active.pluck(:group_id).include?(record.shopping_list.group_id)
  end
end
