# frozen_string_literal: true

# Manages article items.
#
# Handles creating, reading, updating, and previewing articles (items) in the advent calendar.
class ItemsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update preview]
  before_action :find_item, only: %i[show edit update]
  before_action :edit_permission?, only: %i[edit update]

  # Shows an item (article).
  #
  # @return [void]
  def show
    if @item.advent_calendar_item.published?
      @comment = Comment.new(item_id: @item.id)
      @comment.user_name = current_user.name if user_signed_in?
      @advent_calendar_item_prev = AdventCalendarItem.prev(@item.advent_calendar_item).first
      @advent_calendar_item_next = AdventCalendarItem.next(@item.advent_calendar_item).first
    else
      redirect_to root_path
    end
  end

  # Displays a form to create a new item.
  #
  # @return [void]
  def new
    @date = params[:date]
    @item = Item.new(advent_calendar_item_id: params[:id])
    @attachment = Attachment.new(advent_calendar_item_id: params[:id])
  end

  # Displays a form to edit an item.
  #
  # @return [void]
  def edit
    @attachment = Attachment.new(advent_calendar_item_id: @item.advent_calendar_item_id)
  end

  # Creates a new item.
  #
  # @return [void]
  def create
    @item = Item.new(item_params)

    if @item.save
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    else
      render :new
    end
  end

  # Updates an existing item.
  #
  # @return [void]
  def update
    @item.assign_attributes(item_params)

    if @item.save
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    else
      render :edit
    end
  end

  # Previews an item without saving.
  #
  # @return [void]
  def preview
    @item = if params[:id]
              item = Item.find_by(id: params[:id])
              render_not_found and return unless item

              item.tap { |i| i.assign_attributes(item_params) }
            else
              Item.new(item_params)
            end
  end

  private

  def item_params
    params.expect(item: %i[title body advent_calendar_item_id])
  end

  def find_item
    @item = Item.find_by(id: params[:id])
    render_not_found unless @item
  end

  def edit_permission?
    return true if current_user.admin?

    render_forbidden unless @item.editable_by? current_user
  end
end
