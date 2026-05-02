require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "has UUID as primary key" do
    group = Group.create!(name: "Bären")
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, group.id)
  end

  test "has created_at and updated_at timestamps" do
    group = Group.create!(name: "Löwen")
    assert_not_nil group.created_at
    assert_not_nil group.updated_at
  end

  test "updated_at changes after update, created_at stays the same" do
    group = Group.create!(name: "Tiger")
    original_created_at = group.created_at
    sleep 0.01
    group.update!(name: "Tiger-Gruppe")
    assert_equal original_created_at.to_i, group.created_at.to_i
    assert group.updated_at >= original_created_at
  end

  test "name is required" do
    group = Group.new
    assert_not group.valid?
    assert_includes group.errors[:name], "muss ausgefüllt werden"
  end
end
