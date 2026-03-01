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
    if !user_signed_in? or !current_user.admin?
      render_403
    end
  end

  # Renders a 404 not found error page.
  #
  # @return [void]
  def render_404
    render template: 'errors/notfound', status: 404, layout: 'application', content_type: 'text/html'
  end

  # Renders a 403 forbidden error page.
  #
  # @return [void]
  def render_403
    render 'errors/forbidden', status: :forbidden
  end
end
