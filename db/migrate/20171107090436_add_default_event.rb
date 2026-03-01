# frozen_string_literal: true

class AddDefaultEvent < ActiveRecord::Migration[4.2]
  def up
    items = AdventCalendarItem.order(:date)
    return unless items.length.positive?

    admin = User.find_by(name: 'admin')
    Rails.logger.debug admin
    Event.reset_column_information
    event = Event.create!({
                            title: 'automatically generated',
                            name: 'auto_gen',
                            start: Date.new(Constants::YEAR, Constants::MONTH, items.first.date),
                            end: Date.new(Constants::YEAR, Constants::MONTH, items.last.date),
                            created_by_id: admin.id,
                            updated_by_id: admin.id
                          })

    items.each do |item|
      item.event = event
      item.user = admin
      item.save!
    end
  end
end
