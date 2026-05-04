class CalendarBirthdayResolver
  Entry = Struct.new(:date, :child, keyword_init: true) do
    def title       = child.full_name
    def new_age     = date.year - child.date_of_birth.year
    def to_partial_path = "shared/calendar_birthday_entry"
  end

  def initialize(user)
    @user = user
  end

  # Returns Array<Entry> for all visible children whose birthday falls
  # within the inclusive date range. Each entry's `date` is the actual
  # date in `range` (not the original date_of_birth).
  def for_range(range)
    return [] if range.nil?
    children = visible_children
    children.flat_map do |child|
      occurrences_in_range(child.date_of_birth, range).map do |d|
        Entry.new(date: d, child: child)
      end
    end.sort_by(&:date)
  end

  # Returns Hash<Date, Array<Entry>> for fast per-day lookup.
  def grouped_for_range(range)
    for_range(range).group_by(&:date)
  end

  private

  def visible_children
    base = Child.active.includes(:group).where.not(date_of_birth: nil)
    return base if @user&.staff?
    return Child.none unless @user
    group_ids = @user.children.active.pluck(:group_id).uniq
    base.where(group_id: group_ids)
  end

  def occurrences_in_range(date_of_birth, range)
    (range.first.year..range.last.year).filter_map do |year|
      d = safe_date(date_of_birth, year)
      d if d && range.cover?(d)
    end
  end

  # Handles Feb 29 in non-leap years by collapsing to Feb 28.
  def safe_date(dob, year)
    Date.new(year, dob.month, dob.day)
  rescue Date::Error
    Date.new(year, dob.month, dob.day - 1) if dob.month == 2 && dob.day == 29
  end
end
