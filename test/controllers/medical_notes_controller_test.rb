require "test_helper"

class MedicalNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker    = User.create!(email: "betreuer_mh@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent       = User.create!(email: "eltern_mh@mikiwa.at",   password: SecureRandom.hex(20),   role: "parent")
    @other_parent = User.create!(email: "other_mh@mikiwa.at",    password: SecureRandom.hex(20),   role: "parent")
    @group = Group.create!(name: "Monde")
    @year  = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @child = Child.create!(
      first_name: "Mia", last_name: "Lang",
      date_of_birth: Date.new(2022, 7, 20),
      group: @group, kindergarten_year: @year,
      photo_consent: false
    )
    ParentChild.create!(user: @parent, child: @child)
    @mn = MedicalNote.create!(child: @child, note_type: "allergy", content: "Milchallergie")
  end

  test "caretaker can create medical note" do
    sign_in_as(@caretaker)
    assert_difference "MedicalNote.count", 1 do
      post child_medical_notes_path(@child), params: {
        medical_note: { note_type: "medication", content: "Voltaren Emulgel" }
      }
    end
    assert_redirected_to child_path(@child)
  end

  test "parent can create note for own child" do
    sign_in_as(@parent)
    assert_difference "MedicalNote.count", 1 do
      post child_medical_notes_path(@child), params: {
        medical_note: { note_type: "special_note", content: "Schläft mittags" }
      }
    end
    assert_redirected_to child_path(@child)
  end

  test "parent has no access to other child (403)" do
    sign_in_as(@other_parent)
    post child_medical_notes_path(@child), params: {
      medical_note: { note_type: "allergy", content: "X" }
    }
    assert_response :forbidden
  end

  test "invalid type returns error render" do
    sign_in_as(@caretaker)
    assert_no_difference "MedicalNote.count" do
      post child_medical_notes_path(@child), params: {
        medical_note: { note_type: "invalid", content: "X" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "caretaker can update medical note" do
    sign_in_as(@caretaker)
    patch child_medical_note_path(@child, @mn), params: {
      medical_note: { content: "Milchallergie (aktualisiert)" }
    }
    assert_redirected_to child_path(@child)
    assert_equal "Milchallergie (aktualisiert)", @mn.reload.content
  end

  test "caretaker can delete medical note" do
    sign_in_as(@caretaker)
    assert_difference "MedicalNote.count", -1 do
      delete child_medical_note_path(@child, @mn)
    end
    assert_redirected_to child_path(@child)
  end
end
