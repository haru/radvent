# frozen_string_literal: true

class AddBoardToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :board_id, :integer
    add_index :events, :board_id

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE events
          SET board_id = (SELECT id FROM boards WHERE board_type = 0 LIMIT 1)
          WHERE board_id IS NULL
        SQL
      end
    end

    change_column_null :events, :board_id, false
  end
end
