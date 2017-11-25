class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.references :item, index: true
      t.string :user_name
      t.string :body

      t.timestamps
    end
  end
end
