# frozen_string_literal: true

module Users
  # Handles account registration through Devise while keeping the shared Devise views.
  class RegistrationsController < Devise::RegistrationsController
    include Users::DeviseViews
    include MyPostsListing

    # Prepares the first page of the "my posts" tab for the my page and for its re-render on a failed update.
    #
    # Runs after Devise's +authenticate_scope!+ (a prepended callback), so +current_user+ is present.
    before_action :load_my_posts, only: %i[edit update] # rubocop:disable Rails/LexicallyScopedActionFilter

    # Caps sign-ups per connection at 5 per hour (FR-010).
    #
    # Every submission counts, including ones that fail validation, so a bot cannot probe for free.
    # +prepend: true+ rejects the request before Devise builds the account, so nothing is created
    # (FR-012). Showing the form and changing or deleting an account are not limited.
    #
    # @return [void]
    rate_limit to: 5, within: 1.hour, only: :create, prepend: true,
               with: :render_too_many_requests

    private

    # Assigns the first page of the signed-in user's posts.
    #
    # @return [void]
    def load_my_posts
      assign_my_posts(current_user, page: 1)
    end
  end
end
