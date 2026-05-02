require "test_helper"

class ChildPhotoConsentTest < ActiveSupport::TestCase
  setup do
    @group = Group.create!(name: "Consent-Bären")
    @year  = KindergartenYear.create!(
      label: "KGJ 2025/26", start_date: Date.new(2025, 9, 1),
      end_date: Date.new(2026, 7, 31), active: true
    )
    @child = Child.create!(
      first_name: "Finn", last_name: "Muster",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: false
    )
  end

  test "photo_consent_updated_at is set on create" do
    assert_not_nil @child.photo_consent_updated_at
  end

  test "photo_consent_updated_at updates when consent changes" do
    original_ts = @child.photo_consent_updated_at
    sleep 0.01
    @child.update!(photo_consent: true)
    assert @child.photo_consent_updated_at > original_ts
  end

  test "photo_consent_updated_at does not change when other field changes" do
    @child.update!(photo_consent: true)
    ts_after_consent = @child.photo_consent_updated_at
    sleep 0.01
    @child.update!(first_name: "Finn2")
    assert_equal ts_after_consent.to_i, @child.reload.photo_consent_updated_at.to_i
  end

  test "transfer_to copies photo_consent flag to new year" do
    @child.update!(photo_consent: true)
    new_year = KindergartenYear.create!(
      label: "KGJ 2026/27", start_date: Date.new(2026, 9, 1),
      end_date: Date.new(2027, 7, 31), active: false
    )
    new_child = @child.transfer_to(new_year)
    assert_equal true, new_child.photo_consent
  end
end
