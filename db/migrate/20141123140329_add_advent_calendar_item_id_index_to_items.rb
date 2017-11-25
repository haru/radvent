class AddAdventCalendarItemIdIndexToItems < ActiveRecord::Migration[4.2]
  def change
  	add_index :items, :advent_calendar_item_id, unique: true
  end
end
