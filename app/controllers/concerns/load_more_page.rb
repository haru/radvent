# frozen_string_literal: true

# Shared page-number validation for the "load more" Turbo Frame endpoints.
#
# Page 1 is always rendered by the host page itself, so endpoints using this
# concern only accept page 2 and above.
module LoadMorePage
  extend ActiveSupport::Concern

  private

  # Returns the requested page number after explicit validation.
  #
  # Renders 422 and halts when +page+ is missing, not an integer, or smaller
  # than 2 (page 1 is rendered by the host page itself; no silent fallback).
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
end
