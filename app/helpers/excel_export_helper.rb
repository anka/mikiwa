module ExcelExportHelper
  # Mikiwa-Branding-Farben (RGB ohne #) für caxlsx-Styles.
  ACCENT_RGB     = "C4971E".freeze
  ACCENT_ON_RGB  = "FFFFFF".freeze
  SUBTLE_BG_RGB  = "F5F1E6".freeze
  WEEKEND_BG_RGB = "EEEEEE".freeze
  PRESENT_BG_RGB = "D9F2D9".freeze
  ABSENT_BG_RGB  = "F8D7DA".freeze
  NEUTRAL_BG_RGB = "F0F0F0".freeze

  HEADER_STYLE = {
    b: true,
    bg_color: ACCENT_RGB,
    fg_color: ACCENT_ON_RGB,
    alignment: { horizontal: :center, vertical: :center, wrap_text: true },
    border:    { style: :thin, color: "888888" }
  }.freeze

  SUB_HEADER_STYLE = {
    b: true,
    bg_color: SUBTLE_BG_RGB,
    alignment: { horizontal: :left, vertical: :center }
  }.freeze

  WEEKEND_STYLE = {
    bg_color: WEEKEND_BG_RGB,
    fg_color: "888888"
  }.freeze

  PRESENT_STYLE = {
    bg_color: PRESENT_BG_RGB,
    alignment: { horizontal: :center }
  }.freeze

  ABSENT_STYLE = {
    bg_color: ABSENT_BG_RGB,
    alignment: { horizontal: :center }
  }.freeze

  NEUTRAL_STYLE = {
    bg_color: NEUTRAL_BG_RGB,
    alignment: { horizontal: :center }
  }.freeze

  DIETARY_SUFFIXES = {
    "vegetarian" => " (V)",
    "vegan"      => " (V+)"
  }.freeze

  # Filename-Helper:
  #   Ohne weitere parts: 'mikiwa_{prefix}_{YYYY-MM-DD}.xlsx' (aktuelles Datum)
  #   Mit parts:          'mikiwa_{prefix}_{parts.join('_')}.xlsx' (parts liefern bereits Datums-Anteile)
  # Beispiele:
  #   export_filename("kinder")                                     → "mikiwa_kinder_2026-05-14.xlsx"
  #   export_filename("speiseplan", "baeren", "2026-05-04", "2026-05-10")
  #     → "mikiwa_speiseplan_baeren_2026-05-04_2026-05-10.xlsx"
  def export_filename(prefix, *parts)
    cleaned = parts.compact.map(&:to_s).reject(&:blank?)
    segments = if cleaned.empty?
      [ "mikiwa", prefix, Date.current.to_fs(:iso8601) ]
    else
      [ "mikiwa", prefix, *cleaned ]
    end
    "#{segments.join('_')}.xlsx"
  end

  # Dietary-Suffix für Speiseplan-Cells: '' / ' (V)' / ' (V+)'
  def dietary_short(value)
    DIETARY_SUFFIXES.fetch(value.to_s, "")
  end
end
