# Represents a like on an article.
#
# Likes associate a user with an item they've liked.
class Like < ApplicationRecord
  belongs_to :item
  belongs_to :user
end
