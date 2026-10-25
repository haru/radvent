# frozen_string_literal: true

# Manages advent calendar item slots.
#
# Handles creating, reading, updating, and deleting calendar day slots for advent calendar events.
class AdventCalendarItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_slot_creation_authorization, only: %i[new create]
  before_action :find_calendar_item, only: %i[show edit update destroy]
  before_action :check_visibility, only: [:show]
  before_action :edit_permission?, only: %i[show edit update destroy]
  before_action :find_board

  # Shows the slot info page (the author's management page).
  #
  # Restricted to the slot's editor and admins: +authenticate_user!+ redirects guests to sign-in,
  # +check_visibility+ answers 404 for a hidden board, and +edit_permission?+ answers 403 for
  # everyone else. See ADR-0010.
  #
  # @return [void]
  def show; end

  # Displays a form to create a new advent calendar item.
  #
  # @return [void]
  def new
    @advent_calendar_item = @event.advent_calendar_items.build(date: params[:date],
                                                               user_name: current_user.name)
  end

  # Displays a form to edit an advent calendar item.
  #
  # @return [void]
  def edit; end

  # Creates a new advent calendar item.
  #
  # @return [void]
  def create
    @advent_calendar_item = @event.advent_calendar_items.build(advent_calendar_item_params)
    @advent_calendar_item.user = current_user
    if @advent_calendar_item.save
      redirect_to @advent_calendar_item
    else
      render :new, status: :unprocessable_content
    end
  end

  # Updates an existing advent calendar item.
  #
  # @return [void]
  def update
    @advent_calendar_item.user ||= current_user
    if @advent_calendar_item.update(advent_calendar_item_params)
      redirect_to @advent_calendar_item
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deletes an advent calendar item.
  #
  # @return [void]
  def destroy
    event = @advent_calendar_item.event
    if @advent_calendar_item.destroy
      redirect_to helpers.event_page_path(event), status: :see_other
    else
      redirect_to @advent_calendar_item, alert: t('advent_calendar_items.delete_failed'), status: :see_other
    end
  end

  private

  # Returns the permitted slot attributes for create and update.
  #
  # The event assignment is deliberately excluded: the target event is resolved and authorized
  # by +check_slot_creation_authorization+ on creation, and never changes on update.
  #
  # @return [ActionController::Parameters]
  def advent_calendar_item_params
    params.expect(advent_calendar_item: %i[user_name comment date])
  end

  def find_calendar_item
    @advent_calendar_item = AdventCalendarItem.find_by(id: params[:id])
    render_not_found unless @advent_calendar_item
  end

  # Renders 404 unless the viewer may read the board this slot belongs to.
  #
  # Declared before +find_board+ so a hidden slot never exposes its board name in the layout, and
  # before +edit_permission?+ so a hidden board answers 404 rather than 403.
  #
  # @return [void]
  def check_visibility
    render_not_found unless @advent_calendar_item.visible?(current_user)
  end

  # Renders 404/403 unless the requester may join the target event.
  #
  # +new+ resolves the event from +params[:event_id]+ and +create+ from
  # +advent_calendar_item[event_id]+ only, so the event used for the decision is always the
  # event the slot is created in. An event the requester cannot see is answered with 404 so its
  # existence is not revealed. Declared before +find_board+ so a hidden board never exposes its
  # name in the layout.
  #
  # @return [void]
  def check_slot_creation_authorization
    event_id = action_name == 'new' ? params[:event_id] : params.dig(:advent_calendar_item, :event_id)
    @event = Event.find_by(id: event_id)
    return render_not_found unless @event&.visible?(current_user)
    return if @event.joinable?(current_user)

    render_forbidden
  end

  def find_board
    event = @advent_calendar_item&.event || @event
    @board = event&.board
    @breadcrumb_event = event
  end

  # Renders 403 unless the user is an admin or the slot's editor.
  #
  # Guards +show+ as well as the write actions, because the slot info page is an authoring page.
  # Must stay after +check_visibility+ so a hidden board is answered with 404, not 403.
  #
  # @return [void]
  def edit_permission?
    return true if current_user.admin?

    render_forbidden unless @advent_calendar_item.editable_by? current_user
  end
end
