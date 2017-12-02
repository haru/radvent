require 'radvent/version'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  include HttpAcceptLanguage::AutoLocale

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def admin_user!
    if !user_signed_in? or !current_user.admin?
      render 'errors/forbidden', status: :forbidden
    end
  end

  def render_404
    render template: 'errors/notfound', status: 404, layout: 'application', content_type: 'text/html'
  end
end
