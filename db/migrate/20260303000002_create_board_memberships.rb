# frozen_string_literal: true

class CreateBoardMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :board_memberships do |t|
      t.integer :board_id, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_index :board_memberships, %i[board_id user_id], unique: true
    add_index :board_memberships, :user_id
    add_foreign_key :board_memberships, :boards
    add_foreign_key :board_memberships, :users
  end
end
