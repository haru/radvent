# frozen_string_literal: true

# Manages user boards.
#
# Handles creating, viewing, editing, and deleting UserBoards.
class BoardsController < ApplicationController
  before_action :require_authentication, only: %i[index new create edit update destroy]
  before_action :find_board, only: %i[show edit update destroy]
  before_action :check_visibility, only: [:show]
  before_action :check_editability, only: %i[edit update]
  before_action :check_deletability, only: [:destroy]

  def index
    @boards = current_user.admin? ? Board.where(board_type: :user) : Board.where(owner: current_user)
  end

  def new
    @board = Board.new
  end

  def create
    @board = Board.new(board_params)
    @board.owner = current_user
    if @board.save
      redirect_to board_path(@board.board_id), notice: t('boards.created')
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @events = @board.events.order(start_date: :desc)
  end

  def edit; end

  def update
    if @board.update(board_params)
      redirect_to board_path(@board.board_id), notice: t('boards.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @board.destroy
    redirect_to boards_path, status: :see_other, notice: t('boards.deleted')
  end

  private

  def require_authentication
    return if user_signed_in?

    redirect_to new_user_session_path
  end

  def find_board
    @board = Board.find_by(board_id: params[:board_id])
    render_not_found unless @board
  end

  def check_visibility
    render_not_found unless @board&.visible?(current_user)
  end

  def check_editability
    render_forbidden unless @board&.editable?(current_user)
  end

  def check_deletability
    render_forbidden unless @board&.deletable?(current_user)
  end

  def board_params
    params.require(:board).permit(:board_id, :name, :description, :visibility)
  end
end
