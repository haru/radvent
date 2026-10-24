# frozen_string_literal: true

# Manages advent calendar events.
#
# Handles creating, reading, updating, and deleting events, as well as displaying the calendar view.
class EventsController < ApplicationController
  include EventLookup

  before_action :set_events_menu
  before_action :check_event_creation_authorization, only: %i[new create]
  before_action :find_event, except: %i[new create]
  before_action :check_visibility, only: %i[show edit update destroy]
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
      redirect_to helpers.event_page_path(@event), status: :see_other, notice: t('events.updated')
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

  # Resolves the board an event is created on.
  #
  # @param board_id [String, nil] the requested board id; a blank value means the TOP board
  # @return [Board, nil] the board, or nil when a given id matches no board
  # @raise [ActiveRecord::RecordNotFound] when the id is blank and no TOP board exists
  def target_board(board_id)
    if board_id.present?
      Board.find_by(id: board_id)
    else
      Board.find_by!(board_type: :top)
    end
  end

  # Renders 404/403 unless the requester may create an event on the target board.
  #
  # +new+ resolves the board from +params[:board_id]+ (the board the form shows; blank means TOP)
  # and +create+ from +event[board_id]+ only, so the board used for the decision is always the
  # board the event is actually created on. A board the requester cannot see is answered with 404
  # so its existence is not revealed. +@board+ is assigned only after the visibility check passes,
  # so the 404 layout never exposes the name of a hidden board.
  #
  # @return [void]
  def check_event_creation_authorization
    board_id = action_name == 'new' ? params[:board_id] : params.dig(:event, :board_id)
    board = target_board(board_id)
    return render_not_found unless board&.visible?(current_user)

    @board = board
    return if Event.creatable_on?(@board, current_user)

    render_forbidden
  end

  def build_event
    event = Event.new(params.expect(event: %i[title start_date end_date name description]))
    event.created_by = current_user
    event.updated_by = current_user
    event.board = @board
    event
  end

  # Renders 404 unless the viewer may read the board this event belongs to.
  #
  # Declared before +find_board+ so a hidden event never exposes its board name in the layout.
  # +find_event+ leaves +@event+ nil when the name param is blank, which is treated as not found.
  #
  # @return [void]
  def check_visibility
    render_not_found unless @event&.visible?(current_user)
  end

  def find_board
    return unless @event

    @board = @event.board
  end

  def check_edit_permission
    render_forbidden unless @event.editable?(current_user)
  end

  def split_week(range)
    weeks = []
    week = []

    range.each do |date|
      week << date
      if date.wday == 6
        weeks << week
        week = []
      end
    end
    weeks
  end
end
