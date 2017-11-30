class EventsController < ApplicationController
  layout 'admin'
  before_action :set_events_menu
  before_action :admin_user!, except: [:show]
  before_action :find_event, except: [:index, :new, :create, :list, :show]
  before_action :find_event_by_name, only: [:show]

  def new
    @event ||= Event.new
  end

  def create
    @event = Event.new
    @event.attributes = params.require(:event).permit(:title, :start_date, :end_date, :name, :description)
    @event.created_by = current_user
    @event.updated_by = current_user
    if @event.save
      redirect_to events_list_path
    else
      render :new
    end
  end

  def update
    @event.attributes = params.require(:event).permit(:title, :start_date, :end_date, :name, :description)
    @event.updated_by = current_user
    if @event.save
      redirect_to edit_event_path(@event.id)
    else
      render :edit
    end
  end

  def edit
  end

  def destroy
    if @event.destroy
      redirect_to events_list_path
    else
      render :edit
    end
  end

  def index
    @events = Event.order('start_date desc')
  end

  def list
    @events = Event.order('start_date desc')
  end

  def show
    from_date = @event.start_date.beginning_of_week(:sunday)
    to_date = @event.end_date.end_of_week(:sunday)
    @calendar_data = split_week(from_date.upto(to_date))
    @advent_calendar_items = AdventCalendarItem.where(event_id: @event.id)
    render :layout => 'application'
  end

  private

  def set_events_menu
    @menu = :events
  end

  def find_event
    return if params[:id].blank?
    @event = Event.find_by_id(params[:id])
    render_404 unless @event
  end

  def find_event_by_name
    return if params[:name].blank?
    @event = Event.find_by_name(params[:name])
    render_404 unless @event
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
