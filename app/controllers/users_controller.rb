class UsersController < ApplicationController
  before_action :admin_user!
  before_action :find_user, except: [:index]
  def index
    @menu = :users
    @users = User.all
    render layout: 'admin'
  end

  def show
  end

  def edit
    @menu = :users
    render layout: 'admin'
  end

  def update
    @user.attributes =params.require(:user).permit(:email, :name, :admin)
    if (@user.save)
      redirect_to edit_user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user.destroy!
    redirect_to users_path
  end

  private

  def find_user
    @user = User.find(params[:id])
  end
end