# frozen_string_literal: true

module Users
  # Handles account registration through Devise while keeping the shared Devise views.
  class RegistrationsController < Devise::RegistrationsController
    include Users::DeviseViews

    # Caps sign-ups per connection at 5 per hour (FR-010).
    #
    # Every submission counts, including ones that fail validation, so a bot cannot probe for free.
    # +prepend: true+ rejects the request before Devise builds the account, so nothing is created
    # (FR-012). Showing the form and changing or deleting an account are not limited.
    #
    # @return [void]
    rate_limit to: 5, within: 1.hour, only: :create, prepend: true,
               with: :render_too_many_requests
  end
end
