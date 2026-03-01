# frozen_string_literal: true

class AddUniqueIndexesToEvents < ActiveRecord::Migration[8.1]
  def change
    add_index :events, :title, unique: true
    add_index :events, :name, unique: true
  end
end
