# frozen_string_literal: true

# Manages users in the system.
#
# Handles listing, showing, editing info, and deleting users (admin functions).
class UsersController < ApplicationController
  before_action :admin_user!, only: %i[index update_info destroy]
  before_action :find_user, only: %i[show edit_info update_info destroy]

  # Lists all users (admin view).
  #
  # @return [void]
  def index
    @menu = :users
    @users = User.all
    render layout: 'admin'
  end

  # Shows a user profile.
  #
  # @return [void]
  def show; end

  # Displays a form to edit user info (admin view).
  #
  # @return [void]
  def edit_info
    @menu = :users
    render layout: 'admin'
  end

  # Updates user info.
  #
  # @return [void]
  def update_info
    @user.attributes = params.expect(user: %i[email name admin])
    if @user.save
      redirect_to edit_user_path(@user)
    else
      render :edit_info
    end
  end

  # Deletes a user.
  #
  # @return [void]
  def destroy
    @user.destroy!
    redirect_to users_path, status: :see_other
  end

  private

  def find_user
    @user = User.find(params[:id])
  end
end
