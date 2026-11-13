# frozen_string_literal: true

# Searches articles by keyword from the title bar.
#
# +index+ renders the result screen (first page); +page+ returns a "load more" Turbo Frame fragment. Both
# recompute the same ordered list of readable item ids and cut their page out of it.
class SearchesController < ApplicationController
  include LoadMorePage

  # Number of results per page.
  PAGE_SIZE = 20
  # Longest accepted search text, in characters, after stripping.
  MAX_QUERY_LENGTH = 100
  # Characters that are never valid in a query: control characters other than whitespace (e.g. NUL).
  INVALID_QUERY_CHARS = /[[:cntrl:]&&[^[:space:]]]/
  # HTTP status of the guidance rendered for each query problem.
  QUERY_PROBLEM_STATUS = { blank: :ok, too_long: :unprocessable_content }.freeze

  rate_limit to: 30, within: 1.minute, by: -> { request.remote_ip }, with: :render_rate_limited
  before_action :require_search_text
  before_action :require_load_more_page, only: :page
  before_action :no_store

  # Renders the search result screen (page 1), or only a guidance message when the query is blank (200)
  # or too long (422).
  #
  # @return [void]
  def index
    problem = query_problem
    return render_notice(problem, QUERY_PROBLEM_STATUS.fetch(problem)) if problem

    @page = 1
    assign_results
  end

  # Renders the requested page (2 and above) of the results as a Turbo Frame fragment.
  #
  # @return [void]
  def page
    return head :unprocessable_content if query_problem

    assign_results
    render layout: false
  end

  private

  # Reads +q+ and sets +@search_query+ (stripped; a missing +q+ counts as empty) and +@keywords+ (split on
  # half- and full-width whitespace, duplicates dropped, case-sensitively). Responds 400 when +q+ is not a
  # string or contains a control character.
  #
  # @return [void]
  def require_search_text
    raw = params[:q]
    return head :bad_request unless raw.nil? || (raw.is_a?(String) && !raw.match?(INVALID_QUERY_CHARS))

    @search_query = raw.to_s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
    @keywords = @search_query.split(/[[:space:]]+/).uniq
  end

  # Names what is wrong with the query, if anything.
  #
  # @return [Symbol, nil] +:blank+, +:too_long+, or nil when the query can be searched
  def query_problem
    return :blank if @search_query.empty?

    :too_long if @search_query.length > MAX_QUERY_LENGTH
  end

  # Prevents caching of results, which depend on the viewer.
  #
  # @return [void]
  def no_store
    response.headers['Cache-Control'] = 'no-store'
  end

  # Loads the readable ids, the total and the items of the current page.
  #
  # The ids and the page items come from two queries, so an item deleted in between raises +KeyError+
  # (a 500, deliberately not papered over; see ADR 0015).
  #
  # @return [void]
  def assign_results
    ids = Item.search_readable(@keywords, current_user)
    @search_total = ids.size
    offset = (@page - 1) * PAGE_SIZE
    @search_items = load_items(offset < ids.size ? ids.slice(offset, PAGE_SIZE) : [])
    @search_next_page = @page + 1 if ids.size > offset + PAGE_SIZE
  end

  # Loads the items of one page, keeping the order of +ids+.
  #
  # @param ids [Array<Integer>] the item ids of the page
  # @return [Array<Item>] the items, with slot, event and board loaded
  # @raise [KeyError] when an id no longer exists
  def load_items(ids)
    by_id = Item.where(id: ids).includes(advent_calendar_item: { event: :board }).index_by(&:id)
    ids.map { |id| by_id.fetch(id) }
  end

  # Renders the result screen with only a guidance message.
  #
  # @param key [Symbol] the +search.index+ message key
  # @param status [Symbol] the HTTP status
  # @return [void]
  def render_notice(key, status)
    @search_notice = key
    render :index, status: status
  end

  # Responds to a request over the rate limit with 429.
  #
  # +index+ and a +page+ request with an invalid page get the full 429 page (see
  # ApplicationController#render_too_many_requests). A valid +page+ request gets a notice inside its own
  # Turbo Frame, so the frame is not left empty. The locale is set here because the rate limit runs before
  # the locale callback.
  #
  # @return [void]
  def render_rate_limited
    @page = action_name == 'page' ? parse_load_more_page : nil
    return render_too_many_requests unless @page

    set_locale
    Rails.logger.warn("Rate limit exceeded: #{controller_path}##{action_name}")
    render :rate_limited, layout: false, status: :too_many_requests
  end
end
