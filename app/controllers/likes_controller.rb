# frozen_string_literal: true

# Manages likes on articles.
#
# Handles creating and deleting likes on items. Both actions require a signed-in user and an item
# the user can read; anything else is answered with 404 so hidden items are not revealed.
class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :find_readable_item

  # Likes an item once; liking again leaves the existing like in place.
  #
  # @return [void]
  def create
    @item.likes.find_or_create_by(user: current_user)
    respond_with_item
  end

  # Removes the requester's likes of an item, including duplicate rows.
  #
  # The like id in the URL is ignored: the target is always the requester's own like(s) on the item,
  # so another user's like cannot be removed by passing its id.
  #
  # @return [void]
  def destroy
    @item.likes.where(user: current_user).destroy_all
    respond_with_item
  end

  private

  # Loads the item or renders 404 when it does not exist or the requester cannot read it.
  #
  # @return [void]
  def find_readable_item
    @item = Item.find_by(id: params[:item_id])
    render_not_found unless @item&.readable?(current_user)
  end

  # Replies with the refreshed like area (Turbo Stream) or back to the item (HTML).
  #
  # @return [void]
  def respond_with_item
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @item }
    end
  end
end
