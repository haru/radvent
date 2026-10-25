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
  # The URL is built from the persisted name, so a form re-rendered after a failed rename still
  # targets the event being edited rather than the rejected new name.
  #
  # @param event [Event] the event
  # @return [String] the event page path
  def event_page_path(event)
    name = persisted_event_name(event)
    return show_event_path(name) if event.board.board_type_top?

    board_event_path(event.board.board_id, name)
  end

  # Returns the URL path of an event edit page.
  #
  # TOP board events keep the name-only URL; user board events are addressed by board and name.
  # Follows the same URL rule as {#event_page_path}.
  #
  # @param event [Event] the event
  # @return [String] the event edit path
  def edit_event_page_path(event)
    name = persisted_event_name(event)
    return edit_event_path(name) if event.board.board_type_top?

    edit_board_event_path(event.board.board_id, name)
  end

  # Returns the persisted title of an event.
  #
  # A form re-rendered after a failed edit still holds the typed title in memory; the breadcrumb
  # trail must keep showing the stored title, so unsaved changes are ignored, like
  # {#persisted_event_name}.
  #
  # @param event [Event] the event
  # @return [String] the stored title, or the in-memory title for an event never saved yet
  def persisted_event_title(event)
    event.title_in_database.presence || event.title
  end

  private

  # @param event [Event] the event
  # @return [String] the stored name, or the in-memory name for an unsaved event
  def persisted_event_name(event)
    event.name_in_database.presence || event.name
  end
end
