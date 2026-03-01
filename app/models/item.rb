# Represents an article in an advent calendar.
#
# Items contain the markdown content (body) that users publish on specific dates.
class Item < ApplicationRecord
  belongs_to :advent_calendar_item
  has_many :comments, -> { order('id') }, dependent: :destroy
  has_many :likes, dependent: :destroy

  # Returns the title, or a default placeholder if empty.
  #
  # @return [String] the title or default text
  def title
    self[:title].presence || I18n.t('activerecord.attributes.item.title_empty')
  end

  # Checks if the item can be edited by the given author.
  #
  # @param author [User, nil] the user to check
  # @return [Boolean] true if the item can be edited by the author
  def editable_by?(author)
    advent_calendar_item.editable_by? author
  end

  # Checks if the item has been liked by the given user.
  #
  # @param user [User, nil] the user to check
  # @return [Boolean] true if the user has liked this item
  def liked_by?(user)
    return false unless user
    likes.find_by(user_id: user.id) != nil
  end
end
