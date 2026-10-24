# frozen_string_literal: true

# Resolves the event addressed by an events request.
#
# A board-scoped URL (+/boards/:board_board_id/events/:name+) resolves within that user board;
# a name-only URL (+/events/:name+) always means the TOP board. A name-only URL that matches no
# TOP board event redirects to the board-scoped URL when exactly one visible user board event has
# that name (see +legacy_redirect_or_not_found+).
module EventLookup
  extend ActiveSupport::Concern

  private

  # Assigns +@event+ from the request, or renders 404 / redirects for a legacy URL.
  #
  # Leaves +@event+ nil when +params[:name]+ is blank; +check_visibility+ then renders 404.
  #
  # @return [void]
  def find_event
    return if params[:name].blank?

    @event = locate_event
    return if @event

    legacy_redirect_or_not_found
  end

  # Finds the event addressed by the request.
  #
  # @return [Event, nil]
  def locate_event
    if params[:board_board_id].present?
      Event.on_user_boards.find_by(boards: { board_id: params[:board_board_id] }, name: params[:name])
    else
      Event.on_top_board.find_by(name: params[:name])
    end
  end

  # Handles a name-only URL that matched no TOP board event.
  #
  # +show+ and +edit+ redirect (302) to the board-scoped URL when exactly one visible user board
  # event has the name; everything else is a 404. That includes update and destroy, and any
  # board-scoped URL that misses, which never redirects. An ambiguous name is logged.
  #
  # @return [void]
  def legacy_redirect_or_not_found
    legacy = legacy_match
    return render_not_found unless legacy

    redirect_to legacy_redirect_path(legacy)
  end

  # @return [Event, nil] the sole visible user board event for a name-only show / edit URL
  def legacy_match
    return if params[:board_board_id].present? || !action_name.in?(%w[show edit])

    matches = Event.visible_on_user_boards(params[:name], current_user)
    log_ambiguous_legacy_url(matches.size) if matches.many?
    matches.first if matches.one?
  end

  # @param event [Event] the sole matching event
  # @return [String] the board-scoped path for the current action
  def legacy_redirect_path(event)
    action_name == 'edit' ? helpers.edit_event_page_path(event) : helpers.event_page_path(event)
  end

  # @param count [Integer] the number of visible user board events sharing the name
  # @return [void]
  def log_ambiguous_legacy_url(count)
    Rails.logger.info("legacy event URL ambiguous name=#{params[:name]} visible_matches=#{count}")
  end
end
