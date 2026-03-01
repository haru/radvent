# Represents a comment on an article.
#
# Comments are stored with a user_name string (no user_id) and belong to an Item.
class Comment < ApplicationRecord
  belongs_to :item, counter_cache: true
end
