# frozen_string_literal: true

# Manages advent calendar events.
#
# Handles creating, reading, updating, and deleting events, as well as displaying the calendar view.
class EventsController < ApplicationController
  layout 'admin'
  before_action :set_events_menu
  before_action :admin_user!, except: [:show]
  before_action :find_event, except: %i[index new create list show]
  before_action :find_event_by_name, only: [:show]

  # Lists all events (public view).
  #
  # @return [void]
  def index
    @events = Event.order(start_date: :desc)
  end

  # Shows an event with its calendar view.
  #
  # @return [void]
  def show
    from_date = @event.start_date.beginning_of_week(:sunday)
    to_date = @event.end_date.end_of_week(:sunday)
    @calendar_data = split_week(from_date.upto(to_date))
    @advent_calendar_items = AdventCalendarItem.where(event_id: @event.id)
    render layout: 'application'
  end

  # Displays a form to create a new event.
  #
  # @return [void]
  def new
    @new ||= Event.new
  end

  # Displays a form to edit an event.
  #
  # @return [void]
  def edit; end

  # Creates a new event.
  #
  # @return [void]
  def create
    @event = Event.new
    @event.attributes = params.expect(event: %i[title start_date end_date name description])
    @event.created_by = current_user
    @event.updated_by = current_user
    if @event.save
      redirect_to events_list_path
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
      redirect_to edit_event_path(@event.id)
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deletes an event.
  #
  # @return [void]
  def destroy
    if @event.destroy
      redirect_to events_list_path, status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Lists all events (admin view).
  #
  # @return [void]
  def list
    @events = Event.order(start_date: :desc)
  end

  private

  def set_events_menu
    @menu = :events
  end

  def find_event
    return if params[:id].blank?

    @event = Event.find_by(id: params[:id])
    render_not_found unless @event
  end

  def find_event_by_name
    return if params[:name].blank?

    @event = Event.find_by(name: params[:name])
    render_not_found unless @event
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
