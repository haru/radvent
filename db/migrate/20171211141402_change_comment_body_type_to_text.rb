class ChangeCommentBodyTypeToText < ActiveRecord::Migration[5.1]
  def up
    change_column :comments, :body, :text, default: nil
  end

  def down
    change_column :comments, :body, :string
  end
end
