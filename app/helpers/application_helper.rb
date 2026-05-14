module ApplicationHelper
  # Renders an inline SVG Lucide icon (https://lucide.dev).
  #
  # Per the Mikiwa design system: outline-style, single-stroke, rounded.
  # Stroke is 1.75px for sizes >= 20, 1.5px for smaller. Color follows
  # the parent's `currentColor` so icons tint with the surrounding text.
  #
  #   <%= lucide_icon "calendar-days", size: 20 %>
  def lucide_icon(name, size: 24, stroke_width: nil, **opts)
    paths = LUCIDE_PATHS.fetch(name.to_s) do
      raise ArgumentError, "Unknown Lucide icon: #{name}. Add it to ApplicationHelper::LUCIDE_PATHS."
    end

    stroke_width ||= size >= 20 ? 1.75 : 1.5

    css_class = [ "mw-icon", opts.delete(:class) ].compact.join(" ")

    content_tag(
      :svg,
      paths.html_safe,
      {
        xmlns: "http://www.w3.org/2000/svg",
        width: size,
        height: size,
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        "stroke-width": stroke_width,
        "stroke-linecap": "round",
        "stroke-linejoin": "round",
        "aria-hidden": "true",
        focusable: "false",
        class: css_class
      }.merge(opts)
    )
  end

  # Returns the next occurrence of a recurring birthday on or after `today`.
  # Centralised so both BirthdaysController and the shared birthdays_hero
  # partial use the same logic.
  def next_birthday(date_of_birth, today = Date.today)
    return nil unless date_of_birth
    bday = date_of_birth.change(year: today.year)
    bday < today ? bday.change(year: today.year + 1) : bday
  end

  def whatsapp_share_url(title, page_url)
    text = "#{title} – #{page_url}"
    "https://wa.me/?text=#{CGI.escape(text)}"
  end

  def nav_active?(path_prefix)
    active = request.path == path_prefix || request.path.start_with?("#{path_prefix}/")
    active ? "mw-nav-link--active" : nil
  end

  NOTE_TYPE_LABELS = {
    "allergy"      => "Allergie",
    "medication"   => "Medikament",
    "special_note" => "Besonderheit"
  }.freeze

  NOTE_TYPE_BADGE_TONES = {
    "allergy"      => "danger",
    "medication"   => "warning",
    "special_note" => "info"
  }.freeze

  def note_type_label(type)
    NOTE_TYPE_LABELS.fetch(type, type.humanize)
  end

  def child_age_label(child)
    return nil if child.age.nil?
    t("children.age.year", count: child.age)
  end

  def shopping_item_category_label(category_key)
    if category_key.blank?
      t("shopping_items.uncategorized")
    else
      t("activerecord.attributes.shopping_item.categories.#{category_key}", default: category_key.to_s.humanize)
    end
  end

  def shopping_item_category_icon(category_key)
    if category_key.blank?
      "alert-circle"
    else
      ShoppingItem::CATEGORY_ICONS.fetch(category_key, "inbox")
    end
  end

  def group_shopping_items_by_category(items)
    grouped = items.group_by { |i| i.category.presence }
    ordered = ShoppingItem::CATEGORY_ORDER.filter_map do |key|
      next nil unless grouped[key]
      [ key, grouped[key] ]
    end
    ordered << [ nil, grouped[nil] ] if grouped[nil].present?
    ordered
  end

  def badge_tone_for(type)
    NOTE_TYPE_BADGE_TONES.fetch(type, "neutral")
  end

  # Path-data for the small Lucide subset we use today. Add icons here on
  # demand — keep the list lean and copy paths verbatim from lucide.dev so
  # they stay 1:1 with the upstream set.
  LUCIDE_PATHS = {
    "check"           => '<path d="M20 6 9 17l-5-5"/>',
    "check-circle-2"  => '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    "calendar-days"   => '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/>',
    "message-circle"  => '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>',
    "users-round"     => '<path d="M18 21a8 8 0 0 0-16 0"/><circle cx="10" cy="8" r="5"/><path d="M22 20c0-3.37-2-6.5-4-8a5 5 0 0 0-.45-8.3"/>',
    "users"           => '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 1-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    "layout-grid"     => '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
    "calendar-range"  => '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4"/><path d="M3 10h18"/><path d="M8 2v4"/><path d="M17 14h-6"/><path d="M13 18H7"/><path d="M7 14h.01"/><path d="M17 18h.01"/>',
    "user"            => '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
    "log-out"         => '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" x2="9" y1="12" y2="12"/>',
    "shield-check"    => '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
    "calendar"        => '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/>',
    "calendar-plus"   => '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/>',
    "map-pin"         => '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>',
    "clock"           => '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
    "list"            => '<line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/>',
    "chevron-left"    => '<path d="m15 18-6-6 6-6"/>',
    "chevron-right"   => '<path d="m9 18 6-6-6-6"/>',
    "pencil"          => '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>',
    "trash-2"         => '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/>',
    "plus"            => '<path d="M5 12h14"/><path d="M12 5v14"/>',
    "x"               => '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
    "filter"          => '<polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>',
    "link"            => '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
    "share-2"         => '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" x2="15.42" y1="13.51" y2="17.49"/><line x1="15.41" x2="8.59" y1="6.51" y2="10.49"/>',
    "bar-chart-2"     => '<line x1="18" x2="18" y1="20" y2="10"/><line x1="12" x2="12" y1="20" y2="4"/><line x1="6" x2="6" y1="20" y2="14"/>',
    "clipboard-list"  => '<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><line x1="12" x2="16" y1="11" y2="11"/><line x1="12" x2="16" y1="16" y2="16"/><line x1="8" x2="8.01" y1="11" y2="11"/><line x1="8" x2="8.01" y1="16" y2="16"/>',
    "shopping-cart"   => '<circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>',
    "image"           => '<rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
    "download"        => '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/>',
    "inbox"           => '<polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>',
    "send"            => '<path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/>',
    "utensils"        => '<path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/>',
    "paperclip"       => '<path d="m21.44 11.05-9.19 9.19a6 6 0 0 1-8.49-8.49l8.57-8.57A4 4 0 1 1 18 8.84l-8.59 8.57a2 2 0 0 1-2.83-2.83l8.49-8.48"/>',
    "cake"            => '<path d="M20 21v-8a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8"/><path d="M4 16s.5-1 2-1 2.5 2 4 2 2.5-2 4-2 2.5 2 4 2 2-1 2-1"/><path d="M2 21h20"/><path d="M7 8v3"/><path d="M12 8v3"/><path d="M17 8v3"/><path d="M7 4h.01"/><path d="M12 4h.01"/><path d="M17 4h.01"/>',
    "sun"             => '<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/>',
    "check-square"    => '<path d="m9 11 3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>',
    "image-off"       => '<line x1="2" x2="22" y1="2" y2="22"/><path d="M10.41 10.41a2 2 0 1 1-2.83-2.83"/><line x1="13.5" x2="6" y1="13.5" y2="21"/><line x1="18" x2="21" y1="12" y2="15"/><path d="M3.59 3.59A1.99 1.99 0 0 0 3 5v14a2 2 0 0 0 2 2h14c.55 0 1.052-.22 1.41-.59"/><path d="M21 15V5a2 2 0 0 0-2-2H9"/>',
    "image-plus"      => '<path d="M16 5h6"/><path d="M19 2v6"/><path d="M21 11.5V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7.5"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>',
    "clipboard-x"     => '<rect width="8" height="4" x="8" y="2" rx="1" ry="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><line x1="10" x2="14" y1="11" y2="15"/><line x1="14" x2="10" y1="11" y2="15"/>',
    "alert-circle"    => '<circle cx="12" cy="12" r="10"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/>',
    "user-plus"       => '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/>',
    "gift"            => '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/>',
    "mail"            => '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
    "arrow-right"     => '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
    "eye"             => '<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/>',
    "eye-off"         => '<path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/><path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/><path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/><line x1="2" x2="22" y1="2" y2="22"/>',
    "user-check"      => '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><polyline points="16 11 18 13 22 9"/>',
    "home"            => '<path d="M3 9.5 12 3l9 6.5V20a2 2 0 0 1-2 2h-3v-7H10v7H5a2 2 0 0 1-2-2Z"/>',
    "moon"            => '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9z"/>',
    "menu"            => '<line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="18" y2="18"/>',
    "printer"         => '<polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect width="12" height="8" x="6" y="14"/>',
    "leaf"            => '<path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19.2 2.96a1 1 0 0 1 1.6.7A18 18 0 0 1 11 20Z"/><path d="M2 22 17 7"/>',
    "sprout"          => '<path d="M7 20h10"/><path d="M10 20c5.5-2.5.8-6.4 3-10"/><path d="M9.5 9.4c1.1.8 1.8 2.2 2.3 3.7-2 .4-3.5.4-4.8-.3-1.2-.6-2.3-1.9-3-4.2 2.8-.5 4.4 0 5.5.8z"/><path d="M14.1 6a7 7 0 0 0-1.1 4c1.9-.1 3.3-.6 4.3-1.4 1-1 1.6-2.3 1.7-4.6-2.7.1-4 1-4.9 2z"/>',
    "search"          => '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>'
  }.freeze

  # F34: Liefert das Diät-Icon (Lucide sprout/leaf) für einen MealCourse oder
  # nil bei Standard.
  def diet_icon(course_or_dietary)
    dietary = course_or_dietary.respond_to?(:dietary) ? course_or_dietary.dietary : course_or_dietary
    case dietary
    when "vegetarian"
      lucide_icon "sprout", size: 14, class: "mw-diet-icon mw-diet-icon--vegetarian", title: "Vegetarisch"
    when "vegan"
      lucide_icon "leaf",   size: 14, class: "mw-diet-icon mw-diet-icon--vegan",      title: "Vegan"
    end
  end
end
