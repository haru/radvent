# frozen_string_literal: true

class CreateAttachments < ActiveRecord::Migration[4.2]
  def change
    create_table :attachments do |t|
      t.references :advent_calendar_item, index: true
      t.string :image

      t.timestamps
    end
  end
end
