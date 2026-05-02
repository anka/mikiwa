class CalendarEventGroup < ApplicationRecord
  include UuidPrimaryKey

  belongs_to :calendar_event
  belongs_to :group
end
