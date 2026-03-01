# Manages advent calendar item slots.
#
# Handles creating, reading, updating, and deleting calendar day slots for advent calendar events.
class AdventCalendarItemsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :find_calendar_item, only: [:show, :edit, :update, :destroy]
  before_action :edit_permission?, only: [:edit, :update, :destroy]

  # Displays a form to create a new advent calendar item.
  #
  # @return [void]
  def new
    @advent_calendar_item = AdventCalendarItem.new(date: params[:date],
                                                   user_name: current_user.name,
                                                   event_id: params[:event_id])
  end

  # Creates a new advent calendar item.
  #
  # @return [void]
  def create
    advent_calendar_item = AdventCalendarItem.new(advent_calendar_item_params)
    advent_calendar_item.user = current_user if user_signed_in?
    advent_calendar_item.save!
    redirect_to advent_calendar_item
  end

  # Shows an advent calendar item.
  #
  # @return [void]
  def show
  end

  # Displays a form to edit an advent calendar item.
  #
  # @return [void]
  def edit
  end

  # Updates an existing advent calendar item.
  #
  # @return [void]
  def update
    @advent_calendar_item.user ||= current_user
    if @advent_calendar_item.update(advent_calendar_item_params)
      redirect_to @advent_calendar_item
    else
      render :edit
    end
  end

  # Deletes an advent calendar item.
  #
  # @return [void]
  def destroy
    event = @advent_calendar_item.event
    @advent_calendar_item.destroy
    redirect_to show_event_path(event.name)
  end

  private

  def advent_calendar_item_params
    params.require(:advent_calendar_item).permit(:user_name, :comment, :date, :event_id)
  end

  def find_calendar_item
    @advent_calendar_item = AdventCalendarItem.find_by(id: params[:id])
    render_404 unless @advent_calendar_item
  end

  def edit_permission?
    return true if current_user.admin?

    render_403 unless @advent_calendar_item.editable_by? current_user
  end
end
