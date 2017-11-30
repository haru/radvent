class Like < ActiveRecord::Base
  belongs_to :item
  belongs_to :user
end
