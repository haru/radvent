# frozen_string_literal: true

# Represents a container for Advent Calendar events.
#
# Two kinds exist: the single system-level TopBoard (root /) and user-created UserBoards (/boards/:board_id).
class Board < ApplicationRecord
  include Permissionable

  RESERVED_IDS = %w[
    boards admin users events items likes comments attachments
    advent_calendar_items user welcome new edit sign_in sign_out
    sign_up password confirmation unlock rails assets
  ].freeze

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
                         format: { with: /\A[a-z0-9_-]+\z/ },
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

  def deletable?(user)
    return false if board_type_top?
    return true if user&.admin?

    owner?(user)
  end

  private

  def normalize_board_id
    return if board_id.blank?

    self.board_id = board_id.downcase.strip
  end

  def only_one_top_board
    return unless Board.where(board_type: :top).where.not(id: id).exists?

    errors.add(:board_type, :taken)
  end
end
