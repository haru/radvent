# frozen_string_literal: true

class AddThemeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :theme, :string, null: false, default: 'system'
  end
end
