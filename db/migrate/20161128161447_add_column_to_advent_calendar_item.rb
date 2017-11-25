class AddColumnToAdventCalendarItem < ActiveRecord::Migration[4.2]
  def change
    add_column :advent_calendar_items, :user_id, :integer
  end
end
