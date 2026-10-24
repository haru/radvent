# frozen_string_literal: true

# Manages article items.
#
# Handles creating, reading, updating, and previewing articles (items) in the advent calendar.
class ItemsController < ApplicationController
  before_action :authenticate_user!, only: %i[new create edit update preview]
  before_action :check_article_creation_authorization, only: %i[new create]
  before_action :find_item, only: %i[show edit update]
  before_action :check_visibility, only: [:show]
  before_action :edit_permission?, only: %i[edit update]
  before_action :find_board

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
    @item = Item.new(advent_calendar_item: @advent_calendar_item)
    @attachment = Attachment.new(advent_calendar_item: @advent_calendar_item)
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
    @item = Item.new(article_params)
    @item.advent_calendar_item = @advent_calendar_item

    if @item.save
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    else
      render :new, status: :unprocessable_content
    end
  end

  # Updates an existing item.
  #
  # @return [void]
  def update
    @item.assign_attributes(article_params)

    if @item.save
      redirect_to advent_calendar_item_path(id: @item.advent_calendar_item_id)
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Previews an item without saving.
  #
  # @return [void]
  def preview
    @item = if params[:id]
              item = Item.find_by(id: params[:id])
              render_not_found and return unless item

              item.tap { |i| i.assign_attributes(preview_params) }
            else
              Item.new(preview_params)
            end
  end

  private

  # Returns the permitted article attributes for create and update.
  #
  # The slot assignment is deliberately excluded: the target slot is resolved and authorized by
  # +check_article_creation_authorization+ on creation, and never changes on update.
  #
  # @return [ActionController::Parameters]
  def article_params
    params.expect(item: %i[title body])
  end

  # Returns the permitted attributes for the preview.
  #
  # Unlike +article_params+ it still accepts +advent_calendar_item_id+, which the preview needs to
  # render the slot's author and date. The preview never saves, so the slot is not re-assigned.
  #
  # @return [ActionController::Parameters]
  def preview_params
    params.expect(item: %i[title body advent_calendar_item_id])
  end

  def find_item
    @item = Item.find_by(id: params[:id])
    render_not_found unless @item
  end

  # Renders 404/403 unless the requester may write an article on the target slot.
  #
  # +new+ resolves the slot from +params[:id]+ and +create+ from +item[advent_calendar_item_id]+
  # only, so the slot used for the decision is always the slot the article is created on. A slot
  # the requester cannot see is answered with 404 so its existence is not revealed. The publish
  # date is not part of the decision: the owner may write before it, and an admin may write on
  # any visible slot. Declared before +find_board+ so a hidden slot never exposes its board name
  # in the layout.
  #
  # @return [void]
  def check_article_creation_authorization
    slot_id = action_name == 'new' ? params[:id] : params.dig(:item, :advent_calendar_item_id)
    @advent_calendar_item = AdventCalendarItem.find_by(id: slot_id)
    return render_not_found unless @advent_calendar_item&.visible?(current_user)
    return if current_user.admin? || @advent_calendar_item.editable_by?(current_user)

    render_forbidden
  end

  # Renders 404 unless the viewer may read the board this item belongs to.
  #
  # Declared before +find_board+ so a hidden item never exposes its board name in the layout.
  #
  # @return [void]
  def check_visibility
    render_not_found unless @item.visible?(current_user)
  end

  def edit_permission?
    return true if current_user.admin?

    render_forbidden unless @item.editable_by? current_user
  end

  def find_board
    aci = @item&.advent_calendar_item || @advent_calendar_item || AdventCalendarItem.find_by(id: params[:id])
    @board = aci&.event&.board
  end
end
