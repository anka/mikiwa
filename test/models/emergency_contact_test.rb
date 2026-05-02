require "test_helper"

class EmergencyContactTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Löwen")
    @year = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @child = Child.create!(
      first_name: "Finn", last_name: "Berger",
      date_of_birth: Date.new(2021, 5, 10),
      group: @group, kindergarten_year: @year,
      photo_consent: true
    )
  end

  test "emergency contact is saved" do
    ec = EmergencyContact.create!(child: @child, name: "Maria Berger", relationship: "Mutter", phone: "+43 664 123456", position: 1)
    assert ec.persisted?
    assert_equal "Maria Berger", EmergencyContact.find(ec.id).name
    assert_equal "+43 664 123456", EmergencyContact.find(ec.id).phone
  end

  test "encryption: phone is encrypted at rest" do
    ec = EmergencyContact.create!(child: @child, name: "Maria Berger", relationship: "Mutter", phone: "+43 664 123456", position: 1)
    raw = ActiveRecord::Base.connection.exec_query(
      "SELECT phone FROM emergency_contacts WHERE id = '#{ec.id}'"
    ).first["phone"]
    assert_not_equal "+43 664 123456", raw
  end

  test "encryption: name is encrypted at rest" do
    ec = EmergencyContact.create!(child: @child, name: "Maria Berger", relationship: "Mutter", phone: "+43 664 123456", position: 1)
    raw = ActiveRecord::Base.connection.exec_query(
      "SELECT name FROM emergency_contacts WHERE id = '#{ec.id}'"
    ).first["name"]
    assert_not_equal "Maria Berger", raw
  end

  test "required fields: name, phone, relationship" do
    ec = EmergencyContact.new(child: @child, position: 1)
    assert_not ec.valid?
    assert ec.errors[:name].any?
    assert ec.errors[:phone].any?
    assert ec.errors[:relationship].any?
  end

  test "sorted by position" do
    EmergencyContact.create!(child: @child, name: "Oma", relationship: "Großmutter", phone: "111", position: 2)
    EmergencyContact.create!(child: @child, name: "Papa", relationship: "Vater", phone: "222", position: 1)
    assert_equal %w[Papa Oma], @child.emergency_contacts.map(&:name)
  end
end
