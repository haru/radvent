# frozen_string_literal: true

class AddBoardToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :board_id, :integer
    add_index :events, :board_id
  end
end
