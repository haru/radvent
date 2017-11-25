class AllowLongTextToItemsBody < ActiveRecord::Migration[4.2]
  def up
    add_column :items, :body_new, :text
    Item.reset_column_information
    Item.find_each { |i| i.update_attribute(:body_new, i.body) }
    remove_column :items, :body
    rename_column :items, :body_new, :body
  end

  def down
    add_column :items, :body_old, :string
    Item.reset_column_information
    Item.find_each { |i| i.update_attribute(:body_old, i.body[0..250]) } # 250文字で切り捨て
    remove_column :items, :body
    rename_column :items, :body_old, :body
  end
end
