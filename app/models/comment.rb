# frozen_string_literal: true

# Represents a comment on an article.
#
# Comments are stored with a user_name string (no user_id) and belong to an Item.
class Comment < ApplicationRecord
  include Permissionable

  belongs_to :item, counter_cache: true

  # --- Permissionable implementation ---

  def visible?(user)
    item.visible?(user)
  end

  def editable?(_user)
    false
  end

  def deletable?(user)
    return true if user&.admin?
    return false if user.nil?

    item.advent_calendar_item.event.board.owner?(user)
  end
end
