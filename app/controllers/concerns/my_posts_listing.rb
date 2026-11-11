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
  # +@my_posts+ receives the slots of the page and +@my_posts_next_page+ the
  # next page number (nil when everything is already shown).
  #
  # @param user [User] the owner of the posts
  # @param page [Integer] 1-based page number (20 slots per page)
  # @return [Array<AdventCalendarItem>] the slots assigned to +@my_posts+
  def assign_my_posts(user, page: 1)
    posts = AdventCalendarItem.posts_of(user)
    @my_posts = posts.slice((page - 1) * PAGE_SIZE, PAGE_SIZE) || []
    @my_posts_next_page = posts.size > page * PAGE_SIZE ? page + 1 : nil
    @my_posts
  end
end
