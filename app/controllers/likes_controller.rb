# Manages likes on articles.
#
# Handles creating and deleting likes on items.
class LikesController < ApplicationController
  # Creates a like on an item.
  #
  # @return [void]
  def create
    @like = Like.create(user_id: current_user.id, item_id: params[:item_id])
    @likes = Like.where(item_id: params[:item_id])
    @item = Item.find_by(id: params[:item_id])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @item }
    end
  end

  # Deletes a like on an item.
  #
  # @return [void]
  def destroy
    like = Like.find_by(user_id: current_user.id, item_id: params[:item_id])
    like.destroy
    @likes = Like.where(item_id: params[:item_id])
    @item = Item.find_by(id: params[:item_id])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @item }
    end
  end
end
