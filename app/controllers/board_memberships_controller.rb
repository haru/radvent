# frozen_string_literal: true

# Manages board member management.
#
# Handles adding and removing members from UserBoards.
class BoardMembershipsController < ApplicationController
  before_action :require_authentication
  before_action :find_board, only: %i[index create]
  before_action :check_editability, only: %i[index create]
  before_action :find_membership, only: [:destroy]
  before_action :check_membership_deletability, only: [:destroy]

  # Lists all members of the board.
  # @return [void]
  def index
    @memberships = @board.board_memberships.includes(:user)
  end

  # Adds a new member to the board by email or name.
  # @return [void]
  def create
    user = find_user_by_query(params[:member_query])
    return handle_user_not_found unless user

    membership = BoardMembership.new(board: @board, user: user)
    save_membership(membership)
  end

  # Removes a member from the board.
  # @return [void]
  def destroy
    @membership.destroy
    redirect_to board_board_memberships_path(@membership.board.board_id), status: :see_other,
                                                                          notice: t('board_memberships.member_removed')
  end

  private

  def require_authentication
    return if user_signed_in?

    redirect_to new_user_session_path
  end

  def find_board
    @board = Board.find_by(board_id: params[:board_board_id])
    render_not_found unless @board
  end

  def check_editability
    render_forbidden unless @board&.editable?(current_user)
  end

  def find_membership
    @membership = BoardMembership.find_by(id: params[:id])
    render_not_found unless @membership
  end

  def check_membership_deletability
    render_forbidden unless @membership&.board&.editable?(current_user)
  end

  def find_user_by_query(query)
    User.find_by(email: query) || User.find_by(name: query)
  end

  def handle_user_not_found
    flash.now[:alert] = t('board_memberships.errors.user_not_found')
    @memberships = @board.board_memberships.includes(:user)
    render :index, status: :unprocessable_content
  end

  def save_membership(membership)
    if membership.save
      redirect_to board_board_memberships_path(@board.board_id), notice: t('board_memberships.member_added')
    else
      flash.now[:alert] = t('board_memberships.errors.already_member')
      @memberships = @board.board_memberships.includes(:user)
      render :index, status: :unprocessable_content
    end
  end
end
