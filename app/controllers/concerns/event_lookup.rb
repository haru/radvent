# frozen_string_literal: true

# Resolves the event addressed by an events request.
#
# A board-scoped URL (+/boards/:board_board_id/events/:name+) resolves within that user board;
# a name-only URL (+/events/:name+) always means the TOP board, with a legacy redirect for user
# board events that were shared before board-scoped URLs existed.
module EventLookup
  extend ActiveSupport::Concern

  private

  # Assigns +@event+ from the request, or renders 404 / redirects for a legacy URL.
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
  # A board-scoped URL resolves within that user board; a name-only URL always means the TOP board.
  #
  # @return [Event, nil]
  def locate_event
    if params[:board_board_id].present?
      board = Board.board_type_user.find_by(board_id: params[:board_board_id])
      board&.events&.find_by(name: params[:name])
    else
      Event.on_top_board.find_by(name: params[:name])
    end
  end

  # Handles a name-only URL that matched no TOP board event.
  #
  # +show+ and +edit+ redirect (302) to the board-scoped URL when exactly one visible user board
  # event has the name; everything else, including update and destroy, is a 404.
  #
  # @return [void]
  def legacy_redirect_or_not_found
    legacy = params[:board_board_id].blank? && action_name.in?(%w[show edit]) &&
             Event.sole_visible_on_user_boards(params[:name], current_user)
    return render_not_found unless legacy

    path = action_name == 'edit' ? helpers.edit_event_page_path(legacy) : helpers.event_page_path(legacy)
    redirect_to path
  end
end
