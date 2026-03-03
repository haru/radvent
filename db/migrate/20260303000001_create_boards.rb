# frozen_string_literal: true

class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.integer :board_type, null: false, default: 1
      t.string :board_id, limit: 64
      t.string :name, null: false
      t.text :description
      t.integer :visibility
      t.integer :owner_id

      t.timestamps
    end

    add_index :boards, :board_id, unique: true
    add_index :boards, :owner_id
    add_foreign_key :boards, :users, column: :owner_id
  end
end
