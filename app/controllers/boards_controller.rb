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

  # Lists boards owned by the current user (or all user boards for admins).
  # @return [void]
  def index
    @boards = current_user.admin? ? Board.where(board_type: :user) : Board.where(owner: current_user)
  end

  # Displays a board and its events.
  # @return [void]
  def show
    @events = @board.events.order(start_date: :desc)
  end

  # Renders the form to create a new board.
  # @return [void]
  def new
    @board = Board.new
  end

  # Renders the form to edit an existing board.
  # @return [void]
  def edit; end

  # Creates a new board owned by the current user.
  # @return [void]
  def create
    @board = Board.new(board_params)
    @board.owner = current_user
    if @board.save
      redirect_to board_path(@board.board_id), notice: t('boards.created')
    else
      render :new, status: :unprocessable_content
    end
  end

  # Updates an existing board.
  # @return [void]
  def update
    if @board.update(board_params)
      redirect_to board_path(@board.board_id), status: :see_other, notice: t('boards.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deletes a board and redirects to the boards list.
  # @return [void]
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
    params.expect(board: %i[board_id name description visibility])
  end
end
