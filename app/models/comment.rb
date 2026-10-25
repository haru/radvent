# frozen_string_literal: true

# Represents a comment on an article.
#
# Comments are stored with a user_name string (no user_id) and belong to an Item.
class Comment < ApplicationRecord
  include Permissionable

  belongs_to :item, counter_cache: true

  validates :user_name, :body, presence: true
  # Keep within the column sizes (string: 255, text: 64KB in MySQL) so that overlong input is a
  # validation error rather than a database error.
  validates :user_name, length: { maximum: 255 }
  validates :body, length: { maximum: 10_000 }

  # --- Permissionable implementation ---

  # A comment is visible exactly when its item is readable (visible and published).
  #
  # @param user [User, nil]
  # @return [Boolean]
  def visible?(user)
    item&.readable?(user) || false
  end

  def editable?(_user)
    false
  end

  # Only an admin or the owner of the board the item belongs to may delete a comment. This is
  # deliberately not Item#deletable?, which resolves to the event creator's rule.
  #
  # @param user [User, nil]
  # @return [Boolean]
  def deletable?(user)
    calendar_item = item&.advent_calendar_item
    return false unless calendar_item

    calendar_item.event.board.editable?(user)
  end
end
