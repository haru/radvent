# frozen_string_literal: true

# Manages comments on articles.
#
# Handles creating and deleting comments on items.
class CommentsController < ApplicationController
  # Creates a new comment on an item.
  #
  # Anyone, including anonymous users, may comment on an item they can read (Item#readable?).
  # Unknown, hidden and unpublished items all render the same 404 page so that the existence of
  # a hidden item is not revealed.
  #
  # @return [void]
  def create
    item = Item.find_by(id: comment_params[:item_id])
    return render_not_found unless item&.readable?(current_user)

    item.comments.create!(comment_params.slice(:user_name, :body))
    redirect_to item_path(item)
  end

  # Deletes a comment.
  #
  # Only users who may delete the comment (Comment#deletable?: admin or board owner) can do so,
  # even before the item's publish date. Others get 404 when they cannot read the item
  # (Item#readable?), so its existence is not revealed, or 403 when they can.
  #
  # @return [void]
  def destroy
    comment = Comment.find_by(id: params.expect(:id))
    return render_not_found unless comment&.item

    # The order is load-bearing: deletable? does not imply readable? (an admin may delete
    # comments on an unpublished item), so it must be checked first.
    if comment.deletable?(current_user)
      comment.destroy!
      redirect_to item_path(comment.item_id)
    elsif comment.item.readable?(current_user)
      render_forbidden
    else
      render_not_found
    end
  end

  private

  def comment_params
    params.expect(comment: %i[user_name body item_id])
  end
end
