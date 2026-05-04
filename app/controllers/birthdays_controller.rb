class BirthdaysController < ApplicationController
  HERO_DAYS_AHEAD = 7

  def index
    base = Child.active.includes(:group)

    @children = if current_user.staff?
      base.order(:last_name, :first_name)
    else
      group_ids = current_user.children.active.pluck(:group_id).uniq
      base.where(group_id: group_ids).order(:last_name, :first_name)
    end

    today = Date.current
    @children = @children.sort_by { |c| next_birthday(c.date_of_birth, today) }

    window_end = today + HERO_DAYS_AHEAD.days
    @upcoming_birthdays = @children.select do |c|
      next_birthday(c.date_of_birth, today).between?(today, window_end)
    end
    @next_birthday_child = @children.first if @upcoming_birthdays.empty?
    @hero_days_ahead = HERO_DAYS_AHEAD
  end

  private

  def next_birthday(dob, today)
    this_year = dob.change(year: today.year)
    this_year >= today ? this_year : dob.change(year: today.year + 1)
  end
end
