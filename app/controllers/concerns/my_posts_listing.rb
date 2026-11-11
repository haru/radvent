# frozen_string_literal: true

# Shared logic to build the paged "my posts" listing shown on the my page.
#
# The first page is rendered by the my page itself; later pages are served by
# +MyPostsController+ as Turbo Frame fragments.
module MyPostsListing
  extend ActiveSupport::Concern

  # Number of slots shown per page in the my-posts listing.
  PAGE_SIZE = 20

  private

  # Assigns the +@my_posts+ listing ivars for the requested page.
  #
  # +@my_posts+ receives the slots of the page (with the likes of their items preloaded for the
  # like counts) and +@my_posts_next_page+ the next page number (nil when everything is already shown).
  # A page past the last one yields an empty list (e.g. posts removed since the previous page was shown).
  #
  # @param user [User] the owner of the posts
  # @param page [Integer] 1-based page number (+PAGE_SIZE+ slots per page)
  # @return [Array<AdventCalendarItem>] the slots assigned to +@my_posts+
  # @raise [ArgumentError] when +page+ is not an Integer of 1 or more
  def assign_my_posts(user, page: 1)
    raise ArgumentError, "page must be an Integer >= 1, got #{page.inspect}" unless page.is_a?(Integer) && page >= 1

    posts = AdventCalendarItem.posts_of(user)
    offset = (page - 1) * PAGE_SIZE
    @my_posts = offset >= posts.size ? [] : posts.slice(offset, PAGE_SIZE)
    ActiveRecord::Associations::Preloader.new(records: @my_posts.filter_map(&:item), associations: :likes).call
    @my_posts_next_page = posts.size > page * PAGE_SIZE ? page + 1 : nil
    @my_posts
  end
end
