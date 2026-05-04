class GalleryPolicy < ApplicationPolicy
  def index?    = true
  def show?     = staff? || parent_in_any_group?
  def new?      = staff?
  def create?   = staff?
  def edit?     = staff?
  def update?   = staff?
  def destroy?  = staff?
  def add_photo?    = staff?
  def remove_photo? = staff?
  def download? = staff? || parent_in_any_group?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user.staff?

      group_ids = user.children.active.pluck(:group_id)
      scope.joins(:gallery_groups).where(gallery_groups: { group_id: group_ids }).distinct
    end
  end

  private

  def parent_in_any_group?
    return false unless user&.parent?
    parent_group_ids = user.children.active.pluck(:group_id)
    record_group_ids = record.groups.pluck(:id)
    (parent_group_ids & record_group_ids).any?
  end
end
