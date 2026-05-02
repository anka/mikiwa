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

  # Path-data for the small Lucide subset we use today. Add icons here on
  # demand — keep the list lean and copy paths verbatim from lucide.dev so
  # they stay 1:1 with the upstream set.
  LUCIDE_PATHS = {
    "check"          => '<path d="M20 6 9 17l-5-5"/>',
    "check-circle-2" => '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    "calendar-days"  => '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/>',
    "message-circle" => '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>',
    "users-round"    => '<path d="M18 21a8 8 0 0 0-16 0"/><circle cx="10" cy="8" r="5"/><path d="M22 20c0-3.37-2-6.5-4-8a5 5 0 0 0-.45-8.3"/>'
  }.freeze
end
