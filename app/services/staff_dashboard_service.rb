class StaffDashboardService
  def initialize(user)
    @user = user
    @active_year = KindergartenYear.find_by(active: true)
  end

  def today_events
    return Event.none unless @active_year
    Event.active.for_year(@active_year).where(start_date: Date.today).ordered
  end

  def today_meal_entries
    return MealEntry.none unless @active_year
    MealEntry.where(kindergarten_year: @active_year, date: Date.today).ordered
  end

  def today_birthdays
    return Child.none unless @active_year
    today = Date.today
    Child.active.where(kindergarten_year: @active_year).select do |child|
      bday = child.date_of_birth
      bday&.month == today.month && bday&.day == today.day
    end
  end

  UPCOMING_BIRTHDAYS_DAYS = 7

  def upcoming_birthdays(days_ahead: UPCOMING_BIRTHDAYS_DAYS)
    today = Date.today
    window_end = today + days_ahead.days
    sorted_active_children
      .select { |c| next_birthday(c.date_of_birth, today).between?(today, window_end) }
  end

  def next_birthday_child
    sorted_active_children.first
  end

  private

  def sorted_active_children
    @sorted_active_children ||= Child.active.includes(:group).where.not(date_of_birth: nil)
      .sort_by { |c| next_birthday(c.date_of_birth, Date.today) }
  end

  def next_birthday(dob, today)
    bday = dob.change(year: today.year)
    bday < today ? bday.change(year: today.year + 1) : bday
  end

  public

  def events_without_gallery
    return Event.none unless @active_year
    past_event_ids = CalendarEvent.where(
      event_type: "veranstaltung", kindergarten_year: @active_year
    ).where("start_date < ?", Date.today).pluck(:id)
    gallery_event_ids = Gallery.where(event_id: past_event_ids).pluck(:event_id).compact
    missing_ids = past_event_ids - gallery_event_ids
    Event.where(id: missing_ids).ordered.limit(5)
  end

  def open_polls
    return Poll.none unless @active_year
    Poll.where(kindergarten_year: @active_year, status: "open")
        .select(&:open?)
  end

  def lists_without_entries
    return AttendanceList.none unless @active_year
    AttendanceList.where(kindergarten_year: @active_year)
                  .select { |list| list.open? && list.attendance_entries.empty? }
  end

  def children_without_consent
    return Child.none unless @active_year
    Child.active.where(kindergarten_year: @active_year, photo_consent: nil)
  end

  def group_statistics
    return {} unless @active_year
    Group.all.each_with_object({}) do |group, hash|
      count = Child.active.where(group: group, kindergarten_year: @active_year).count
      hash[group] = count
    end
  end

  attr_reader :active_year
end
