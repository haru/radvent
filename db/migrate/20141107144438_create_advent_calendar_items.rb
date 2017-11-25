class CreateAdventCalendarItems < ActiveRecord::Migration[4.2]
  def change
    create_table :advent_calendar_items do |t|
      t.string :user_name
      t.string :comment
      t.integer :date

      t.timestamps
    end
  end
end
