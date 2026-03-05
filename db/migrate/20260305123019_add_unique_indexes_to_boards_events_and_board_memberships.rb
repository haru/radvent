# frozen_string_literal: true

class AddUniqueIndexesToBoardsEventsAndBoardMemberships < ActiveRecord::Migration[8.1]
  def change
    add_index :boards, :board_id, unique: true
    add_index :board_memberships, %i[user_id board_id], unique: true
  end
end
