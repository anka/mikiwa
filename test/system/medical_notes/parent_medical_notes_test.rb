require "test_helper"

class ParentMedicalNotesTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "MedNotes-Gruppe")
    @parent = User.create!(email: "mednote_parent@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @child = Child.create!(
      first_name: "Med-Kind", last_name: "Test",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    ParentChild.create!(user: @parent, child: @child)
  end

  teardown do
    MedicalNote.where(child: @child).destroy_all
    ParentChild.where(user: @parent).destroy_all
    @child.destroy!
    @parent.destroy!
    @group.destroy!
  end

  # TS-035-S01: Elternteil legt medizinischen Hinweis an
  test "TS-035 Elternteil kann medizinischen Hinweis für eigenes Kind anlegen" do
    sign_in_as(@parent)

    assert_difference "MedicalNote.count", 1 do
      post child_medical_notes_path(@child), params: {
        medical_note: { note_type: "allergy", content: "Haselnussallergie" }
      }
    end

    assert_response :redirect

    note = MedicalNote.find_by(child: @child)
    assert note.present?
    assert_equal "Haselnussallergie", note.content
  end
end
