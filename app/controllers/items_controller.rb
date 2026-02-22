class ItemsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update]
  before_action :find_item, only: [:show, :edit, :update]
  before_action :edit_permission?, only: [:edit, :update]
  protect_from_forgery with: :null_session, only: [:preview]

  def new
    @date = params[:date]
    @item = Item.new(advent_calendar_item_id: params[:id])
    @attachment = Attachment.new(advent_calendar_item_id: params[:id])
  end

  def create
    @item = Item.new(item_params)

    if !@item.save
      render :new
    else
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    end
  end

  def show
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
    @attachment = Attachment.new(advent_calendar_item_id: @item.advent_calendar_item_id)
  end

  def update
    @item.assign_attributes(item_params)

    if !@item.save
      render :edit
    else
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    end
  end

  def preview
    @item = if params[:id]
      item = Item.find_by(id: params[:id])
      render_404 and return unless item
      item.tap { |i| i.assign_attributes(item_params) }
    else
      Item.new(item_params)
    end
  end

  private

  def item_params
    params.require(:item).permit(:title, :body, :advent_calendar_item_id)
  end

  def find_item
    @item = Item.find_by(id: params[:id])
    render_404 unless @item
  end

  def edit_permission?
    return true if current_user.admin?

    render_403 unless @item.editable_by? current_user
  end
end
