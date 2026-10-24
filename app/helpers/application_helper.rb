# frozen_string_literal: true

# Helper methods available in all views.
module ApplicationHelper
  # Returns the system title from environment variable or default.
  #
  # @return [String] the system title
  def system_title
    ENV['RADVENT_TITLE'] || 'Advent Calendar'
  end

  # Returns the URL path of an event page.
  #
  # TOP board events keep the name-only URL; user board events are addressed by board and name.
  #
  # @param event [Event] the event
  # @return [String] the event page path
  def event_page_path(event)
    return show_event_path(event.name) if event.board.board_type_top?

    board_event_path(event.board.board_id, event.name)
  end

  # Returns the URL path of an event edit page.
  #
  # @param event [Event] the event
  # @return [String] the event edit path
  def edit_event_page_path(event)
    return edit_event_path(event.name) if event.board.board_type_top?

    edit_board_event_path(event.board.board_id, event.name)
  end
end
