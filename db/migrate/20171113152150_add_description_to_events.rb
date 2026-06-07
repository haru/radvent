# frozen_string_literal: true

class AddDescriptionToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :description, :text
  end
end
