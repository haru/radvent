# frozen_string_literal: true

# Shared logic to build the "other boards" listing shown at the bottom of a board page.
#
# Loads all boards (preloading associations for +#list_sort_key+), excludes the
# currently displayed board, keeps only the boards visible to the given user, and
# sorts them by +#list_sort_key+ descending (+Board#id+ ascending on ties).
#
# The visibility filter and exclusion are controller concerns by design: no DB
# schema change and no "listable?" method is added to +Board+ (see data-model.md).
module OtherBoardsListing
  extend ActiveSupport::Concern

  # Number of boards shown per page in the other-boards listing.
  PAGE_SIZE = 10

  private

  # Returns every board that can be listed for the given user.
  #
  # @param current_board [Board] the board currently displayed (excluded from the result)
  # @param user [User, nil] the viewer used for the visibility check
  # @return [Array<Board>] visible boards sorted by newest activity first
  def other_boards(current_board, user)
    Board.includes(events: { advent_calendar_items: :item })
         .select { |board| board.id != current_board.id && board.visible?(user) }
         .sort do |a, b|
           comparison = b.list_sort_key <=> a.list_sort_key
           comparison.zero? ? a.id <=> b.id : comparison
         end
  end

  # Assigns the +@other_boards+ listing ivars for the requested page.
  #
  # +@other_boards+ receives the boards for the page, +@other_boards_more+ the
  # total count of listable boards, and +@other_boards_next_page+ the next page
  # number (nil when everything is already shown).
  #
  # @param current_board [Board] the board currently displayed (excluded from the result)
  # @param user [User, nil] the viewer used for the visibility check
  # @param page [Integer] 1-based page number (10 boards per page)
  # @return [Array<Board>] the boards assigned to +@other_boards+
  def assign_other_boards(current_board, user, page: 1)
    boards = other_boards(current_board, user)
    offset = (page - 1) * PAGE_SIZE
    @other_boards = offset > boards.size ? [] : boards.slice(offset, PAGE_SIZE) || []
    @other_boards_more = boards.size
    @other_boards_next_page = boards.size > page * PAGE_SIZE ? page + 1 : nil
    @other_boards
  end
end
