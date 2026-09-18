# frozen_string_literal: true

# Manages the current user's theme preference.
class ThemesController < ApplicationController
  before_action :authenticate_user!

  # Updates the current user's theme preference.
  #
  # @return [void]
  def update
    unless User.themes.key?(params[:theme])
      render json: { error: 'invalid theme' }, status: :unprocessable_content
      return
    end

    if current_user.update(theme: params[:theme])
      render json: { theme: current_user.theme }
    else
      render json: { error: current_user.errors.full_messages }, status: :unprocessable_content
    end
  end
end
