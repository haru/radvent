# frozen_string_literal: true

# Helper methods for events views.
module EventsHelper
  # Splits a date range into arrays of weeks (Sunday to Saturday).
  #
  # @param range [Enumerator] a range of dates
  # @return [Array<Array<Date>>] an array of week arrays
  def split_week(range)
    weeks = []
    week = []

    range.each do |date|
      week << date
      if date.wday == 6
        weeks << week
        week = []
      end
    end
    weeks
  end
end
