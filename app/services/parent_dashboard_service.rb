class ParentDashboardService
  UPCOMING_DAYS = 14

  def initialize(user)
    @user = user
    @group_ids = user.children.active.pluck(:group_id).uniq
  end

  def unread_messages
    return InboxEntry.none if @group_ids.empty?
    @user.inbox_entries.unread.joins(message: :message_groups)
         .where(message_groups: { group_id: @group_ids })
         .includes(:message)
         .ordered
  end

  def upcoming_events
    return Event.none if @group_ids.empty?
    Event.active
         .for_groups(@group_ids)
         .where(start_date: Date.today..UPCOMING_DAYS.days.from_now.to_date)
         .ordered
  end

  def open_lists
    return AttendanceList.none if @group_ids.empty?
    entered_list_ids = AttendanceEntry.where(child: @user.children.active).pluck(:attendance_list_id)
    AttendanceList.where(group_id: @group_ids)
                  .where.not(id: entered_list_ids)
                  .select { |list| list.open? }
  end

  def open_polls
    return Poll.none if @group_ids.empty?
    voted_option_ids = Vote.where(user: @user).pluck(:poll_option_id)
    voted_poll_ids = PollOption.where(id: voted_option_ids).pluck(:poll_id)
    Poll.where(group_id: @group_ids).select { |p| p.open? && voted_poll_ids.exclude?(p.id) }
  end

  def upcoming_birthdays
    return [] if @group_ids.empty?
    today = Date.today
    window_end = today + UPCOMING_DAYS
    Child.active.where(group_id: @group_ids).select do |child|
      next false unless child.date_of_birth
      next_birthday(child.date_of_birth, today).between?(today, window_end)
    end.sort_by { |child| next_birthday(child.date_of_birth, today) }
  end

  def meal_entries
    return MealEntry.none if @group_ids.empty?
    MealEntry.where(group_id: @group_ids, date: [ Date.today, Date.today + 1 ]).ordered
  end

  private

  def next_birthday(date_of_birth, today = Date.today)
    bday = date_of_birth.change(year: today.year)
    bday < today ? bday.change(year: today.year + 1) : bday
  end
end
