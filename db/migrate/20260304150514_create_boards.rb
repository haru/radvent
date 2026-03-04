# frozen_string_literal: true

class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      t.integer :board_type
      t.string :board_id
      t.string :name
      t.text :description
      t.integer :visibility
      t.integer :owner_id

      t.timestamps
    end

    add_index :boards, :board_id, unique: true
  end
end
