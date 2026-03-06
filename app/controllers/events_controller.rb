# frozen_string_literal: true

# Manages advent calendar events.
#
# Handles creating, reading, updating, and deleting events, as well as displaying the calendar view.
class EventsController < ApplicationController
  include EventsHelper

  before_action :set_events_menu
  before_action :check_event_creation_authorization, only: %i[new create]
  before_action :find_event, except: %i[new create show]
  before_action :find_event_by_name, only: [:show]
  before_action :check_edit_permission, only: %i[edit update destroy]
  before_action :find_board

  # Shows an event with its calendar view.
  #
  # @return [void]
  def show
    from_date = @event.start_date.beginning_of_week(:sunday)
    to_date = @event.end_date.end_of_week(:sunday)
    @calendar_data = split_week(from_date.upto(to_date))
    @advent_calendar_items = AdventCalendarItem.where(event_id: @event.id)
  end

  # Displays a form to create a new event.
  #
  # @return [void]
  def new
    board_id = params[:board_id] || params.dig(:event, :board_id)
    @board = Board.find_by(id: board_id) || Board.find_by(board_type: :top)
    @event ||= Event.new
    @event.board = @board
  end

  # Displays a form to edit an event.
  #
  # @return [void]
  def edit; end

  # Creates a new event.
  #
  # @return [void]
  def create
    @event = build_event
    @board = @event.board
    if @event.save
      redirect_to board_redirect_path(@board)
    else
      render :new, status: :unprocessable_content
    end
  end

  # Updates an existing event.
  #
  # @return [void]
  def update
    @event.attributes = params.expect(event: %i[title start_date end_date name description])
    @event.updated_by = current_user
    if @event.save
      redirect_to show_event_path(@event.name), status: :see_other, notice: t('events.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deletes an event.
  #
  # @return [void]
  def destroy
    if @event.destroy
      redirect_to board_redirect_path(@board), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def board_redirect_path(board)
    board.board_type_top? ? root_path : board_path(board.board_id)
  end

  def set_events_menu
    @menu = :events
  end

  def check_event_creation_authorization
    board_id_param = params[:board_id] || params.dig(:event, :board_id)
    target_board = if board_id_param.present?
                     Board.find_by(id: board_id_param)
                   else
                     Board.find_by!(board_type: :top)
                   end

    return render_not_found unless target_board
    return if Event.creatable_on?(target_board, current_user)

    render_forbidden
  end

  def build_event
    event = Event.new(params.expect(event: %i[title start_date end_date name description board_id]))
    event.created_by = current_user
    event.updated_by = current_user
    event.board ||= Board.find_by!(board_type: :top)
    event
  end

  def find_event
    return if params[:name].blank?

    @event = Event.find_by(name: params[:name])
    render_not_found unless @event
  end

  def find_event_by_name
    return if params[:name].blank?

    @event = Event.find_by(name: params[:name])
    render_not_found unless @event
  end

  def find_board
    return unless @event

    @board = @event.board
  end

  def check_edit_permission
    return unless current_user

    return if current_user.admin? || (@event && @event.created_by_id == current_user.id)

    render_forbidden
    nil
  end
end
