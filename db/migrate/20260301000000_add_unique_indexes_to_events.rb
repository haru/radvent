# frozen_string_literal: true

class AddUniqueIndexesToEvents < ActiveRecord::Migration[7.0]
  def change
    add_index :events, :title, unique: true
    add_index :events, :name, unique: true
  end
end
