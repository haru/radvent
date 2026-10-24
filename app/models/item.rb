# frozen_string_literal: true

# Represents an article in an advent calendar.
#
# Items contain the markdown content (body) that users publish on specific dates.
class Item < ApplicationRecord
  include Permissionable

  belongs_to :advent_calendar_item
  has_many :comments, -> { order(:id) }, dependent: :destroy, inverse_of: :item
  has_many :likes, dependent: :destroy
  validates :advent_calendar_item_id, uniqueness: true

  # Returns the title, or a default placeholder if empty.
  #
  # @return [String] the title or default text
  def title
    self[:title].presence || I18n.t('activerecord.attributes.item.title_empty')
  end

  delegate :editable_by?, to: :advent_calendar_item

  # Checks if the item has been liked by the given user.
  #
  # @param user [User, nil] the user to check
  # @return [Boolean] true if the user has liked this item
  def liked_by?(user)
    return false unless user

    likes.find_by(user_id: user.id) != nil
  end

  # Counts the users who liked this item, a user with duplicate like rows counting once.
  #
  # @return [Integer] the number of distinct users
  def like_count
    likes.distinct.count(:user_id)
  end

  # Lists the users who liked this item, each once, ordered by id.
  #
  # @return [ActiveRecord::Relation<User>] the distinct users
  def liked_users
    User.where(id: likes.select(:user_id)).order(:id)
  end

  # Checks if the given user can read this item: it is visible to them and its publish date has come.
  #
  # Unlike Board#visible?, an unpublished item is not readable by anyone, including admins, the
  # board owner and the author. This mirrors ItemsController#show, which redirects away from
  # unpublished items, so it must not be loosened for privileged users.
  #
  # @param user [User, nil] the user to check
  # @return [Boolean] true if the item is visible and published
  def readable?(user)
    visible?(user) && advent_calendar_item.published?
  end

  # --- Permissionable implementation ---

  delegate :visible?, to: :advent_calendar_item

  delegate :editable?, to: :advent_calendar_item

  delegate :deletable?, to: :advent_calendar_item
end
