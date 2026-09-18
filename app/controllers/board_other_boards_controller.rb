# frozen_string_literal: true

# Serves the "load more" paging of the other-boards listing.
#
# Returns a Turbo Frame fragment with the next page of boards for the
# +other-boards-page-N+ frame matching the requested page (see contracts/other-boards-endpoint.md).
class BoardOtherBoardsController < ApplicationController
  include OtherBoardsListing

  before_action :find_board

  # Returns the requested page of other boards as a Turbo Frame fragment.
  #
  # @return [void]
  def index
    page = page_number
    return if performed?

    assign_other_boards(@board, current_user, page: page)
  end

  private

  # Returns the requested page number after explicit validation.
  #
  # Renders 422 and halts when +page+ is missing, not an integer, or smaller
  # than 2 (page 1 is rendered by the board page itself; no silent fallback).
  #
  # @return [Integer, nil] the validated page number
  def page_number
    page = Integer(params[:page], 10)
    return page if page >= 2

    reject_page
  rescue ArgumentError, TypeError
    reject_page
  end

  # Renders 422 and halts the request for an invalid page number.
  #
  # @return [nil]
  def reject_page
    head :unprocessable_content
    nil
  end

  # Finds the reference board and renders 404 when it is missing or invisible.
  #
  # @return [void]
  def find_board
    @board = Board.find_by(id: params[:board_ref_id])
    render_not_found unless @board&.visible?(current_user)
  end
end
