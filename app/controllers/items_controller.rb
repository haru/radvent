class ItemsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update]

  def new
    @date = params[:date]
    @item = Item.new(advent_calendar_item_id: params[:id])
    @attachment = Attachment.new(advent_calendar_item_id: params[:id])
  end

  def create
    @item = Item.new(item_params)

    if params[:preview_button]
      render :preview
    elsif !@item.save
      render :new
    else
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    end
  end

  def show
    @item = Item.find(params[:id])
    if !@item.advent_calendar_item.published?
      redirect_to root_path
    else
      @comment = Comment.new(item_id: @item.id)
      @comment.user_name = current_user.name if user_signed_in?
      @advent_calendar_item_prev = AdventCalendarItem.prev(@item.advent_calendar_item).first
      @advent_calendar_item_next = AdventCalendarItem.next(@item.advent_calendar_item).first
    end
  end

  def edit
    @item = Item.find(params[:id])
    @attachment = Attachment.new(advent_calendar_item_id: @item.advent_calendar_item_id)
  end

  def update
    @item = Item.find(params[:id])
    @item.assign_attributes(item_params)

    if params[:preview_button]
      render :preview
    elsif !@item.save
      render :edit
    else
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    end
  end

  def preview
  end

  private

  def item_params
    params.require(:item).permit(:title, :body, :advent_calendar_item_id)
  end
end
