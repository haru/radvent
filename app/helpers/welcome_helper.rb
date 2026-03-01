# Helper methods for welcome views.
module WelcomeHelper
  # Checks if a date falls within an advent calendar event's date range.
  #
  # @param date [Date] the date to check
  # @param event [Event] the advent calendar event
  # @return [Boolean] true if the date is within the event's range
  def advent_calendar_date?(date, event)
    date.month == event.start_date.month &&
      date.day >= event.start_date.day &&
      date.day <= event.end_date.day
  end
end
