# frozen_string_literal: true

# Represents an article in an advent calendar.
#
# Items contain the markdown content (body) that users publish on specific dates.
class Item < ApplicationRecord
  include Permissionable

  # Case-insensitive partial match on title or body; +!+ is the escape character (see Board::MATCH_SQL).
  KEYWORD_SQL = "LOWER(items.title) LIKE LOWER(:p) ESCAPE '!' OR LOWER(items.body) LIKE LOWER(:p) ESCAPE '!'"

  # +inverse_of+ is required by .search_readable: AdventCalendarItem#published? reads +item+, and without the
  # inverse every matched slot would query its item again (N+1).
  belongs_to :advent_calendar_item, inverse_of: :item
  has_many :comments, -> { order(:id) }, dependent: :destroy, inverse_of: :item
  has_many :likes, dependent: :destroy
  # The users who liked this item, each once (a user with duplicate like rows counts once), by id.
  has_many :liked_users, -> { distinct.order(:id) }, through: :likes, source: :user
  validates :advent_calendar_item_id, uniqueness: true

  # Returns the ids of the items matching all keywords that the user may read, newest publish date first.
  #
  # Each keyword must appear (case-insensitively, as plain text) in the title or the body. Readability is
  # decided by Board#visible?, memoized per board, and AdventCalendarItem#published?. These are the same
  # primitives #readable? combines, but the combination is repeated here, so it must be kept equivalent to
  # #readable? by hand; spec/models/item_search_readable_spec.rb checks that for every role.
  # Item rows are loaded with only +id+ and the slot id (no title or body).
  #
  # @param keywords [Array<String>] non-empty list of non-blank keywords, all of which must match
  # @param user [User, nil] the viewer, nil for a guest
  # @return [Array<Integer>] item ids ordered by publish date, then id, both descending
  # @raise [ArgumentError] when keywords is empty or contains a blank keyword (never returns every item)
  # @raise [Date::Error] when a matched slot has a date that does not exist in its event's month
  def self.search_readable(keywords, user)
    require_keywords!(keywords)
    visible = Hash.new { |hash, board| hash[board] = board.visible?(user) }.compare_by_identity
    readable = keyword_matches(keywords).select { |item| readable_slot?(item.advent_calendar_item, visible) }
    readable.sort_by { |item| publish_sort_key(item) }.reverse.map(&:id)
  end

  # Guards the search contract: it never turns an empty or blank keyword into "match everything".
  #
  # @param keywords [Array<String>] the keywords
  # @return [void]
  # @raise [ArgumentError] when keywords is empty or contains a blank keyword
  def self.require_keywords!(keywords)
    raise ArgumentError, 'keywords must not be empty or blank' if keywords.empty? || keywords.any?(&:blank?)
  end
  private_class_method :require_keywords!

  # Loads the items matching every keyword with only the columns needed to judge readability.
  #
  # @param keywords [Array<String>] the keywords
  # @return [ActiveRecord::Relation] items with advent_calendar_item, event and board preloaded
  def self.keyword_matches(keywords)
    keywords.reduce(all) { |scope, keyword| scope.where(KEYWORD_SQL, p: like_pattern(keyword)) }
            .select(:id, :advent_calendar_item_id)
            .preload(advent_calendar_item: { event: :board })
  end
  private_class_method :keyword_matches

  # Checks a matched item's slot is published and its board visible, using the per-board memo.
  #
  # @param slot [AdventCalendarItem] the slot with event and board loaded
  # @param visible [Hash{Board => Boolean}] memo of Board#visible? for the viewer
  # @return [Boolean] true when the item can be read
  def self.readable_slot?(slot, visible)
    visible[slot.event.board] && slot.published?
  end
  private_class_method :readable_slot?

  # Builds the sort key of a matched item: its publish date, then its id.
  #
  # @param item [Item] an item whose advent_calendar_item is loaded
  # @return [Array<Integer>] year, month, day and id
  def self.publish_sort_key(item)
    slot = item.advent_calendar_item
    [slot.year, slot.month, slot.date, item.id]
  end
  private_class_method :publish_sort_key

  # Builds the LIKE pattern for a keyword, escaping %, _ and the escape character +!+.
  #
  # @param keyword [String] the keyword
  # @return [String] the pattern
  def self.like_pattern(keyword)
    "%#{sanitize_sql_like(keyword, '!')}%"
  end
  private_class_method :like_pattern

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

    likes.exists?(user_id: user.id)
  end

  # Counts the users who liked this item, a user with duplicate like rows counting once.
  #
  # Uses the already loaded likes (no query) when they were preloaded, e.g. by +includes(:likes)+.
  #
  # @return [Integer] the number of distinct users
  def like_count
    return likes.map(&:user_id).uniq.size if likes.loaded?

    likes.distinct.count(:user_id)
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
