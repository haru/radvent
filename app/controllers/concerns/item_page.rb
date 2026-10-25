# frozen_string_literal: true

# Sets up what the article page (items/show) and the navbar breadcrumb need.
#
# Shared by ItemsController and CommentsController, which re-renders items/show when a comment is
# rejected, so both pages are built from the same instance variables.
module ItemPage
  extend ActiveSupport::Concern

  private

  # Assigns the board and the event shown in the navbar breadcrumb trail.
  #
  # @param calendar_item [AdventCalendarItem, nil] the slot being displayed
  # @return [void]
  def assign_breadcrumb(calendar_item)
    event = calendar_item&.event
    @board = event&.board
    @breadcrumb_event = event
  end

  # Assigns the previous and next slots linked from the article page.
  #
  # @param calendar_item [AdventCalendarItem] the slot being displayed
  # @return [void]
  def assign_neighbours(calendar_item)
    @advent_calendar_item_prev = AdventCalendarItem.prev(calendar_item).first
    @advent_calendar_item_next = AdventCalendarItem.next(calendar_item).first
  end
end
