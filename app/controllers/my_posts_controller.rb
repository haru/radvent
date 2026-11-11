# frozen_string_literal: true

# Serves the "load more" paging of the my page's "my posts" list.
#
# Returns a Turbo Frame fragment (no layout) with the requested page of the
# signed-in user's posts for the +my-posts-page-N+ frame.
class MyPostsController < ApplicationController
  include MyPostsListing
  include LoadMorePage

  before_action :authenticate_user!
  layout false

  # Returns the requested page of the user's posts as a Turbo Frame fragment.
  #
  # @return [void]
  def index
    @page = page_number
    return if performed?

    assign_my_posts(current_user, page: @page)
  end
end
