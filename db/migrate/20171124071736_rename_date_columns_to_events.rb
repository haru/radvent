class RenameDateColumnsToEvents < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :start, :start_date
    rename_column :events, :end, :end_date
  end
end
