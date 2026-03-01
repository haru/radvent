# frozen_string_literal: true

class AddEventIdToAdventCalendarItem < ActiveRecord::Migration[4.2]
  def change
    add_column :advent_calendar_items, :event_id, :integer
  end
end
