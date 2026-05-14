require "test_helper"

class ExcelExportHelperTest < ActionView::TestCase
  include ExcelExportHelper

  test "F59 export_filename ohne extra Parts" do
    travel_to Date.new(2026, 5, 14) do
      assert_equal "mikiwa_kinder_2026-05-14.xlsx", export_filename("kinder")
    end
  end

  test "F59 export_filename mit zusätzlichen Parts" do
    travel_to Date.new(2026, 5, 14) do
      assert_equal "mikiwa_speiseplan_baeren_2026-05-04_2026-05-10.xlsx",
                   export_filename("speiseplan", "baeren", "2026-05-04", "2026-05-10")
    end
  end

  test "F59 export_filename behandelt nil und blank parts" do
    travel_to Date.new(2026, 5, 14) do
      assert_equal "mikiwa_eltern_2026-05-14.xlsx",
                   export_filename("eltern", nil, "")
    end
  end

  test "F59 dietary_short für standard ist leerer String" do
    assert_equal "", dietary_short("standard")
    assert_equal "", dietary_short(nil)
  end

  test "F59 dietary_short für vegetarian liefert ' (V)'" do
    assert_equal " (V)", dietary_short("vegetarian")
  end

  test "F59 dietary_short für vegan liefert ' (V+)'" do
    assert_equal " (V+)", dietary_short("vegan")
  end

  test "F59 Style-Konstanten sind definiert" do
    assert_kind_of Hash, ExcelExportHelper::HEADER_STYLE
    assert_kind_of Hash, ExcelExportHelper::SUB_HEADER_STYLE
    assert_kind_of Hash, ExcelExportHelper::WEEKEND_STYLE
    assert_kind_of Hash, ExcelExportHelper::PRESENT_STYLE
    assert_kind_of Hash, ExcelExportHelper::ABSENT_STYLE
    assert_kind_of Hash, ExcelExportHelper::NEUTRAL_STYLE
  end

  test "F59 HEADER_STYLE setzt bold und Mikiwa-Accent-Hintergrund" do
    assert ExcelExportHelper::HEADER_STYLE[:b], "Header muss bold sein"
    assert ExcelExportHelper::HEADER_STYLE[:bg_color].present?,
           "Header braucht eine Hintergrundfarbe"
  end

  test "F59 :xlsx MIME-Type ist registriert" do
    assert Mime::Type.lookup_by_extension(:xlsx).present?,
           "Mime::Type :xlsx muss registriert sein"
  end
end
