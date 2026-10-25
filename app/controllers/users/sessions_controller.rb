# frozen_string_literal: true

module Users
  # Handles sign-in through Devise while keeping the shared Devise views.
  class SessionsController < Devise::SessionsController
    include Users::DeviseViews

    # Caps sign-in attempts per connection at 10 per minute (FR-010, FR-020).
    #
    # +prepend: true+ runs the check ahead of Devise's own +prepend_before_action+, so a rejected
    # attempt never reaches the password check and adds nothing to the account's failed attempts
    # (FR-012). The counters live in the shared cache store, so every server process counts the
    # same connection (docs/adr/0011-*).
    #
    # @return [void]
    rate_limit to: 10, within: 1.minute, only: :create, prepend: true,
               with: :render_too_many_requests
  end
end
