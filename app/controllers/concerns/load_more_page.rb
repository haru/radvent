# frozen_string_literal: true

# Shared page-number validation for the "load more" Turbo Frame endpoints.
#
# Page 1 is always rendered by the host page itself, so endpoints using this
# concern only accept page 2 and above. Add it as a +before_action+ so that an
# invalid page halts the request.
module LoadMorePage
  extend ActiveSupport::Concern

  private

  # Parses +page+ without any fallback.
  #
  # @return [Integer, nil] the page (2 or more), or nil when +page+ is missing, not a plain run of
  #   digits, or smaller than 2
  def parse_load_more_page
    raw = params[:page]
    page = raw.to_i if raw.is_a?(String) && raw.match?(/\A\d+\z/)
    page if page && page >= 2
  end

  # Sets +@page+ to the requested page number after explicit validation.
  #
  # Renders 422 (halting the action) when +page+ is missing, not a plain run of digits, or
  # smaller than 2 (page 1 is rendered by the host page itself; no silent fallback).
  #
  # @return [void]
  def require_load_more_page
    @page = parse_load_more_page
    head :unprocessable_content unless @page
  end
end
