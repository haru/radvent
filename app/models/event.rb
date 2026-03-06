# frozen_string_literal: true

# Represents an Advent Calendar event.
#
# Events have a title, name, start and end dates, and contain multiple advent calendar items.
class Event < ApplicationRecord
  NAME_FORMAT = /\A(?=[a-z0-9_-]*[a-z])[a-z0-9]([a-z0-9_-]*[a-z0-9])?\z/
  include Permissionable

  belongs_to :board
  has_many :advent_calendar_items, dependent: :destroy
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'
  validates :title, presence: true, uniqueness: { scope: :board_id }
  validates :name, presence: true, uniqueness: { scope: :board_id }, format: { with: NAME_FORMAT }
  validate :start_and_end_dates_must_be_same_month

  # Returns true if the given user can create an event on the given board.
  #
  # @param board [Board] the target board
  # @param user [User, nil]
  # @return [Boolean]
  def self.creatable_on?(board, user)
    return false if user.nil?
    return true if user.admin?
    return false if board.board_type_top?
    return true if board.visibility_public?

    board.owner?(user) || board.member?(user)
  end

  # --- Permissionable implementation ---

  delegate :visible?, to: :board

  def editable?(user)
    return false if user.nil?
    return true if user.admin?

    created_by_id == user.id
  end

  def deletable?(user)
    editable?(user)
  end

  private

  def start_and_end_dates_must_be_same_month
    return if start_date.blank? || end_date.blank?

    return unless start_date.month != end_date.month || start_date.year != end_date.year

    errors.add(:end_date, :different_month)
  end

  public

  # Calculates the total number of days in the event.
  #
  # @return [Integer] the number of days in the event
  def day_count
    (1 + (end_date - start_date)).to_i
  end

  # Counts the number of entries (calendar items) in the event.
  #
  # @return [Integer] the number of advent calendar items
  def entry_count
    return 0 unless advent_calendar_items

    advent_calendar_items.length
  end

  # Calculates the percentage of days that have entries.
  #
  # @return [Integer] the percentage of filled days (0-100)
  def entry_percent
    return 0 unless day_count

    100 * entry_count / day_count
  end
end
