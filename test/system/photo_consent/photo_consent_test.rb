require "test_helper"

class PhotoConsentTest < ActionDispatch::IntegrationTest
  setup do
    @year = KindergartenYear.where(active: true).first || KindergartenYear.create!(
      label: "2025/26", start_date: Date.new(2025, 9, 1), end_date: Date.new(2026, 7, 31), active: true
    )
    @group = Group.create!(name: "Consent-Gruppe")
    @parent_a = User.create!(email: "consent_parent_a@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")
    @parent_b = User.create!(email: "consent_parent_b@mikiwa.at", password: "sicherespasswort1234", role: "parent",
      first_name: "Test",
      last_name: "Parent",
      phone: "0664 000 000")

    @child_a = Child.create!(
      first_name: "ConsentKind", last_name: "A",
      date_of_birth: 5.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: false
    )
    @child_b = Child.create!(
      first_name: "ConsentKind", last_name: "B",
      date_of_birth: 4.years.ago.to_date,
      group: @group, kindergarten_year: @year, photo_consent: false
    )
    ParentChild.create!(user: @parent_a, child: @child_a)
    ParentChild.create!(user: @parent_b, child: @child_b)
  end

  teardown do
    ParentChild.where(user: [ @parent_a, @parent_b ]).destroy_all
    @child_a.destroy!
    @child_b.destroy!
    @parent_a.destroy!
    @parent_b.destroy!
    @group.destroy!
  end

  # TS-051-S01: Elternteil setzt Foto-Einwilligung auf true
  test "TS-051 Elternteil erteilt Foto-Einwilligung für eigenes Kind" do
    sign_in_as(@parent_a)

    travel_to Time.zone.parse("2026-05-03 10:00:00") do
      patch update_consent_child_path(@child_a), params: {
        child: { photo_consent: "1" }
      }
    end

    assert_response :redirect

    @child_a.reload
    assert @child_a.photo_consent?
    assert_not_nil @child_a.photo_consent_updated_at
  end

  # TS-051-S02: Elternteil kann keine Einwilligung für fremdes Kind setzen
  test "TS-051 Elternteil A kann keine Einwilligung für Kind von Elternteil B setzen" do
    sign_in_as(@parent_a)

    patch update_consent_child_path(@child_b), params: {
      child: { photo_consent: "1" }
    }

    assert_response :forbidden
    @child_b.reload
    assert_not @child_b.photo_consent?
  end
end
