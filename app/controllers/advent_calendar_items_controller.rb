class AdventCalendarItemsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update]
  def new
    @advent_calendar_item = AdventCalendarItem.new(date: params[:date], user_name: current_user.name, event_id: params[:event_id])
  end

  def create
    advent_calendar_item = AdventCalendarItem.new(advent_calendar_item_params)
    advent_calendar_item.user = current_user if user_signed_in?
    advent_calendar_item.save!
    redirect_to advent_calendar_item
  end

  def show
    @advent_calendar_item = AdventCalendarItem.find(params[:id])
  end

  def edit
    @advent_calendar_item = AdventCalendarItem.find(params[:id])
  end

  def update
    @advent_calendar_item = AdventCalendarItem.find(params[:id])
    @advent_calendar_item.user ||= current_user
    if @advent_calendar_item.update(advent_calendar_item_params)
      redirect_to @advent_calendar_item
    else
      render :edit
    end
  end

  private
  def advent_calendar_item_params
    params.require(:advent_calendar_item).permit(:user_name, :comment, :date, :event_id)
  end
end
