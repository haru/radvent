# frozen_string_literal: true

# Base controller for all application controllers.
#
# Provides common functionality including CSRF protection, Devise parameter configuration,
# and helper methods for rendering error responses.
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  include HttpAcceptLanguage::AutoLocale

  protected

  # Configures Devise parameters to allow additional fields.
  #
  # @return [void]
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # Requires the current user to be an administrator.
  #
  # Renders a 403 error if the user is not signed in or is not an admin.
  #
  # @return [void]
  def admin_user!
    return unless !user_signed_in? || !current_user.admin?

    render_forbidden
  end

  # Renders a 404 not found error page.
  #
  # @return [void]
  def render_not_found
    render template: 'errors/notfound', status: :not_found, layout: 'application', content_type: 'text/html',
           formats: [:html]
  end

  # Renders a 403 forbidden error page.
  #
  # @return [void]
  def render_forbidden
    render template: 'errors/forbidden', status: :forbidden, layout: 'application', content_type: 'text/html',
           formats: [:html]
  end

  # Renders the 429 page shown when a rate limit rejects the request.
  #
  # The log line names only the controller and action, never the submitted
  # address or password (FR-018). A prepended +rate_limit+ runs before +set_locale+,
  # so the locale is set here to answer in the request's language instead of the one
  # the thread was left with (FR-011).
  #
  # @return [void]
  def render_too_many_requests
    set_locale
    Rails.logger.warn("Rate limit exceeded: #{controller_path}##{action_name}")
    render template: 'errors/too_many_requests', status: :too_many_requests, layout: 'application',
           content_type: 'text/html', formats: [:html]
  end
end
