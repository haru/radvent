# frozen_string_literal: true

# Represents a user's membership in a UserBoard.
#
# A member gains access to Protected/Private boards and event creation rights.
class BoardMembership < ApplicationRecord
  belongs_to :board
  belongs_to :user

  validates :board_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :board_id }

  validate :board_must_be_user_type

  private

  def board_must_be_user_type
    return unless board
    return if board.board_type_user?

    errors.add(:board, :must_be_user_type)
  end
end
