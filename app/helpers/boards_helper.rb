# frozen_string_literal: true

# Helper methods for board views, mainly the "other boards" card listing.
module BoardsHelper
  # Returns the label to show for a board in a listing.
  #
  # The TOP board has a fixed internal name, so the configured site title is
  # shown instead of that literal name.
  #
  # @param board [Board] the board to label
  # @return [String] the display name of the board
  def other_board_label(board)
    board.board_type_top? ? system_title : board.name
  end

  # Returns the path of a board page.
  #
  # @param board [Board] the board to link to
  # @return [String] the root path for the TOP board, the board path otherwise
  def other_board_path(board)
    board.board_type_top? ? root_path : board_path(board.board_id)
  end

  # Returns how many calendars (events) the board holds.
  #
  # Counts in memory so a preloaded +events+ association causes no extra query.
  #
  # @param board [Board] the board to count for
  # @return [Integer] the number of events
  def board_calendar_count(board)
    board.events.size
  end

  # Returns how many published articles the board holds.
  #
  # Counts in memory so a preloaded +events+ association causes no extra query.
  #
  # @param board [Board] the board to count for
  # @return [Integer] the number of published calendar items
  def board_published_item_count(board)
    board.events.sum { |event| event.advent_calendar_items.count(&:published?) }
  end
end
