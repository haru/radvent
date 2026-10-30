# frozen_string_literal: true

# Represents a container for Advent Calendar events.
#
# Two kinds exist: the single system-level TopBoard (root /) and user-created UserBoards (/boards/:board_id).
class Board < ApplicationRecord
  include Permissionable

  # Board IDs that cannot be used by user-created boards to avoid routing conflicts.
  RESERVED_IDS = %w[
    boards admin users events items likes comments attachments
    advent_calendar_items user welcome new edit sign_in sign_out
    sign_up password confirmation unlock rails assets
  ].freeze

  # Number of member candidates offered at once.
  CANDIDATE_LIMIT = 10

  # Case-insensitive partial match on name or email; +!+ is the escape character (see #member_candidates).
  MATCH_SQL = "LOWER(users.name) LIKE LOWER(:p) ESCAPE '!' OR LOWER(users.email) LIKE LOWER(:p) ESCAPE '!'"

  attribute :board_type, :integer, default: 1
  enum :board_type, { top: 0, user: 1 }, prefix: true
  enum :visibility, { public: 0, protected: 1, private: 2 }, prefix: :visibility

  belongs_to :owner, class_name: 'User', optional: true
  has_many :board_memberships, dependent: :destroy
  has_many :members, through: :board_memberships, source: :user
  has_many :events, dependent: :destroy

  before_validation :normalize_board_id

  validates :board_type, presence: true
  validates :name, presence: true

  with_options if: :board_type_user? do
    validates :board_id, presence: true,
                         length: { maximum: 64 },
                         format: { with: /\A(?=[a-z0-9_-]*[a-z])[a-z0-9]([a-z0-9_-]*[a-z0-9])?\z/ },
                         exclusion: { in: RESERVED_IDS },
                         uniqueness: true
    validates :visibility, presence: true
    validates :owner, presence: true
  end

  validate :only_one_top_board, if: :board_type_top?

  # Returns true if the given user is a member of this board.
  #
  # @param user [User, nil]
  # @return [Boolean]
  def member?(user)
    return false if user.nil?

    board_memberships.exists?(user_id: user.id)
  end

  # Returns true if the given user is the owner of this board.
  #
  # @param user [User, nil]
  # @return [Boolean]
  def owner?(user)
    return false if user.nil?

    owner_id == user.id
  end

  # Returns true if the given input matches this board's normalized board_id.
  #
  # The input is normalized the same way as +normalize_board_id+ (stripped and
  # downcased) before comparison, mirroring the existing board_id normalization.
  #
  # @param input [Object, nil] raw user input (e.g. +params[:confirm_board_id]+)
  # @return [Boolean]
  def board_id_match?(input)
    input.to_s.strip.downcase == board_id
  end

  # Returns the datetime used as the ordering key in the other-boards listing.
  #
  # This is the newest of three candidates, in priority order: the updated_at
  # of the board's published (+published?+) items, the created_at of the
  # board's events, and the board's own created_at. Callers are expected to
  # preload associations (e.g. +includes(events: { advent_calendar_items: :item })+);
  # this method must not issue additional queries.
  #
  # @return [Time]
  def list_sort_key
    published_item_updates = events.flat_map do |event|
      event.advent_calendar_items.select(&:published?).map { |calendar_item| calendar_item.item.updated_at }
    end
    event_created_ats = events.map(&:created_at)

    [*published_item_updates, *event_created_ats, created_at].max
  end

  # --- Permissionable implementation ---

  def visible?(user)
    return true if user&.admin?
    return true if board_type_top?

    case visibility
    when 'public', 'protected' then true
    when 'private' then owner?(user) || member?(user)
    else false
    end
  end

  def editable?(user)
    return true if user&.admin?

    owner?(user)
  end

  # Users that can be offered as new members for a search term.
  #
  # Matches the user name or email address by partial, case-insensitive comparison (non-ASCII case
  # folding and the sort order depend on the database). +%+, +_+ and +!+ in the term are plain
  # characters. The owner and existing members are left out. Returns at most CANDIDATE_LIMIT users
  # sorted by name then email, and whether more matched.
  # @param query [String] the search term, already stripped
  # @return [Array(Array<User>, Boolean)] the candidates and whether further users matched
  def member_candidates(query)
    pattern = "%#{User.sanitize_sql_like(query, '!')}%"
    users = addable_users.where(MATCH_SQL, p: pattern).order(:name, :email).limit(CANDIDATE_LIMIT + 1).to_a
    [users.first(CANDIDATE_LIMIT), users.size > CANDIDATE_LIMIT]
  end

  def deletable?(user)
    return false if board_type_top?
    return true if user&.admin?

    owner?(user)
  end

  private

  # Users who are neither the owner nor a member. The join behind +members+ drops rows with a NULL user_id,
  # which would otherwise make NOT IN match nothing.
  def addable_users
    User.where.not(id: members.select(:id)).where.not(id: owner_id)
  end

  def normalize_board_id
    return if board_id.blank?

    self.board_id = board_id.downcase.strip
  end

  def only_one_top_board
    return unless Board.where(board_type: :top).where.not(id: id).exists?

    errors.add(:board_type, :taken)
  end
end
