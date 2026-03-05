# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string :title
      t.string :name
      t.integer :version
      # t.datetime :updated_at
      # t.datetime :created_at
      t.date :start
      t.date :end
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps null: false
    end
  end
end
