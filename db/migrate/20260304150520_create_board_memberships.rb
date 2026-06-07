# frozen_string_literal: true

class CreateBoardMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :board_memberships do |t|
      t.integer :board_id
      t.integer :user_id

      t.timestamps
    end

    add_index :board_memberships, %i[user_id board_id], unique: true
  end
end
