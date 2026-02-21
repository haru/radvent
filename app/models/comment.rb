class Comment < ApplicationRecord
  belongs_to :item, counter_cache: true
end
