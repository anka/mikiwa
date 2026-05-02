class IcalFeedsController < ActionController::Base
  def show
    @user = User.find_by(ical_token: params[:token])
    return head :not_found unless @user

    @events = visible_events_for(@user)
    last_modified = @events.map(&:updated_at).max || Time.current

    response.headers["X-Robots-Tag"] = "noindex"

    if stale?(etag: cache_key_for(@events), last_modified: last_modified, public: false)
      ics_content = build_ics(@events)
      render plain: ics_content, content_type: "text/calendar; charset=utf-8"
    end
  end

  private

  def visible_events_for(user)
    if user.staff?
      CalendarEvent.ordered.includes(:groups)
    else
      group_ids = user.children.active.pluck(:group_id).uniq
      CalendarEvent.for_groups(group_ids).ordered.includes(:groups)
    end
  end

  def cache_key_for(events)
    ids_and_timestamps = events.map { |e| "#{e.id}-#{e.updated_at.to_i}" }.join(",")
    Digest::MD5.hexdigest("#{@user.id}:#{ids_and_timestamps}")
  end

  def build_ics(events)
    lines = []
    lines << "BEGIN:VCALENDAR"
    lines << "VERSION:2.0"
    lines << "PRODID:-//Mikiwa//Mikiwa//DE"
    lines << "CALSCALE:GREGORIAN"
    lines << "METHOD:PUBLISH"
    lines << "X-WR-CALNAME:Mikiwa"

    events.each do |event|
      lines << "BEGIN:VEVENT"
      lines << "UID:#{event.id}@mikiwa"
      lines << "DTSTAMP:#{format_ics_datetime(Time.current)}"
      lines << "LAST-MODIFIED:#{format_ics_datetime(event.updated_at)}"

      if event.all_day
        lines << "DTSTART;VALUE=DATE:#{event.start_date.strftime('%Y%m%d')}"
      else
        datetime = DateTime.new(event.start_date.year, event.start_date.month,
                                event.start_date.day, event.start_time.hour,
                                event.start_time.min, 0)
        lines << "DTSTART:#{datetime.strftime('%Y%m%dT%H%M%S')}"
      end

      lines << "SUMMARY:#{ics_escape(event.title)}"
      lines << "DESCRIPTION:#{ics_escape(event.description.to_s)}" if event.description.present?
      lines << "LOCATION:#{ics_escape(event.location)}" if event.location.present?
      lines << "END:VEVENT"
    end

    lines << "END:VCALENDAR"
    lines.join("\r\n") + "\r\n"
  end

  def format_ics_datetime(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def ics_escape(text)
    text.to_s.gsub("\\", "\\\\").gsub("\n", "\\n").gsub(",", "\\,").gsub(";", "\\;")
  end
end
