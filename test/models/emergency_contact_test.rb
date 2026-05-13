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

  # F38 – User-Verknüpfung
  test "F38 manueller Kontakt: name und phone Pflicht ohne user_id" do
    ec = EmergencyContact.new(child: @child, relationship: "Mutter", position: 1)
    assert_not ec.valid?
    assert ec.errors[:name].any?
    assert ec.errors[:phone].any?
  end

  test "F38 verknüpfter Kontakt: name und phone nicht Pflicht mit user_id" do
    parent = User.create!(email: "nk_parent@test.at", password: "geheimwort12345678", role: "parent",
      first_name: "Maria", last_name: "Huber", phone: "+43 664 1234")
    ParentChild.create!(user: parent, child: @child)
    ec = EmergencyContact.new(child: @child, user: parent, relationship: "Mutter", position: 1)
    assert ec.valid?, ec.errors.full_messages.inspect
  end

  test "F38 display_name gibt user.full_name zurück wenn verknüpft" do
    parent = User.create!(email: "nk_parent2@test.at", password: "geheimwort12345678", role: "parent",
      first_name: "Maria", last_name: "Huber", phone: "+43 664 5678")
    ParentChild.create!(user: parent, child: @child)
    ec = EmergencyContact.create!(child: @child, user: parent, relationship: "Mutter", position: 1)
    assert_equal "Maria Huber", ec.display_name
  end

  test "F38 display_name gibt gespeicherten name zurück wenn nicht verknüpft" do
    ec = EmergencyContact.create!(child: @child, name: "Oma Erna", relationship: "Großmutter", phone: "111", position: 1)
    assert_equal "Oma Erna", ec.display_name
  end

  test "F38 display_phone gibt user.phone zurück wenn verknüpft" do
    parent = User.create!(email: "nk_parent3@test.at", password: "geheimwort12345678", role: "parent",
      first_name: "Anna", last_name: "Wolf", phone: "+43 699 9999")
    ParentChild.create!(user: parent, child: @child)
    ec = EmergencyContact.create!(child: @child, user: parent, relationship: "Mutter", position: 1)
    assert_equal "+43 699 9999", ec.display_phone
  end

  test "F38 linked? gibt true zurück wenn user_id gesetzt" do
    parent = User.create!(email: "nk_parent4@test.at", password: "geheimwort12345678", role: "parent",
      first_name: "Hans", last_name: "Klein", phone: "0664")
    ParentChild.create!(user: parent, child: @child)
    ec = EmergencyContact.create!(child: @child, user: parent, relationship: "Vater", position: 1)
    assert ec.linked?
  end

  test "F38 linked? gibt false zurück ohne user_id" do
    ec = EmergencyContact.create!(child: @child, name: "Opa", relationship: "Großvater", phone: "222", position: 1)
    assert_not ec.linked?
  end

  test "F38 Validation: fremder User kann nicht verknüpft werden" do
    other_child = Child.create!(
      first_name: "Lisa", last_name: "Bauer",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    parent = User.create!(email: "nk_parent5@test.at", password: "geheimwort12345678", role: "parent",
      first_name: "Josef", last_name: "Bauer", phone: "0664")
    ParentChild.create!(user: parent, child: other_child)
    ec = EmergencyContact.new(child: @child, user: parent, relationship: "Vater", position: 1)
    assert_not ec.valid?
    assert ec.errors[:user].any?
  end
end
