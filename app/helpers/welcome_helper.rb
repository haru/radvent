module WelcomeHelper
    def advent_calendar_date?(date, event)
        date.month == event.start_date.month  &&
            date.day >= event.start_date.day &&
            date.day <= event.end_date.day
    end
end
