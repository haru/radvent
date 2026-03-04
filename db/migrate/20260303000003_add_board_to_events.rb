# frozen_string_literal: true

class AddBoardToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :board_id, :bigint
    add_index :events, :board_id

    reversible do |dir|
      dir.up do
        # Seed TopBoard first if it doesn't exist
        top_board_id = select_value('SELECT id FROM boards WHERE board_type = 0 LIMIT 1')

        if top_board_id.nil?
          execute(<<~SQL.squish)
            INSERT INTO boards (board_type, name, created_at, updated_at)
            VALUES (0, 'TOP', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
          SQL
          top_board_id = select_value('SELECT id FROM boards WHERE board_type = 0 LIMIT 1')
        end

        execute("UPDATE events SET board_id = #{top_board_id}")
      end
    end

    change_column_null :events, :board_id, false
    add_foreign_key :events, :boards
  end
end
