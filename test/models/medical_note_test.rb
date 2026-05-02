require "test_helper"

class MedicalNoteTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Bären")
    @year = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @child = Child.create!(
      first_name: "Lena", last_name: "Müller",
      date_of_birth: Date.new(2022, 3, 15),
      group: @group, kindergarten_year: @year,
      photo_consent: false
    )
  end

  test "medical note is saved" do
    mn = MedicalNote.create!(child: @child, note_type: "allergy", content: "Erdnussallergie")
    assert mn.persisted?
    assert_equal "Erdnussallergie", MedicalNote.find(mn.id).content
  end

  test "encryption: content is encrypted at rest" do
    mn = MedicalNote.create!(child: @child, note_type: "allergy", content: "Erdnussallergie")
    raw = ActiveRecord::Base.connection.exec_query(
      "SELECT content FROM medical_notes WHERE id = '#{mn.id}'"
    ).first["content"]
    assert_not_equal "Erdnussallergie", raw
  end

  test "invalid note_type is rejected" do
    mn = MedicalNote.new(child: @child, note_type: "sonstiges", content: "Test")
    assert_not mn.valid?
    assert mn.errors[:note_type].any?
  end

  test "required fields: note_type and content" do
    mn = MedicalNote.new(child: @child)
    assert_not mn.valid?
    assert mn.errors[:note_type].any?
    assert mn.errors[:content].any?
  end

  test "all valid types are accepted" do
    %w[allergy medication special_note].each do |type|
      mn = MedicalNote.new(child: @child, note_type: type, content: "Test")
      assert mn.valid?, "Type '#{type}' should be valid"
    end
  end
end
