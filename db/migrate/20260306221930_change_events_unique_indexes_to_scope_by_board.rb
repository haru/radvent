class ChangeEventsUniqueIndexesToScopeByBoard < ActiveRecord::Migration[8.1]
  def change
    remove_index :events, :title, unique: true
    remove_index :events, :name, unique: true
    add_index :events, [:board_id, :title], unique: true
    add_index :events, [:board_id, :name], unique: true
  end
end
