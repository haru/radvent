# frozen_string_literal: true

# Manages comments on articles.
#
# Handles creating and deleting comments on items.
class CommentsController < ApplicationController
  include ItemPage

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

    # Not built through item.comments: a rejected comment would otherwise join the list that
    # items/show renders when the article is shown again.
    @comment = Comment.new(comment_params.slice(:user_name, :body).merge(item: item))
    return render_invalid(item) unless @comment.save

    render_created(item)
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

  # Answers a saved comment: Turbo appends it in place, so the scroll position is kept.
  #
  # @param item [Item] the item that was commented on
  # @return [void]
  def render_created(item)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to item_path(item) }
    end
  end

  # Answers a rejected comment with 422: a Turbo Stream replaces only the error region, so what the
  # visitor typed stays in the form; a plain request re-renders the article with the errors.
  #
  # @param item [Item] the item that was commented on
  # @return [void]
  def render_invalid(item)
    respond_to do |format|
      format.turbo_stream { render :create_error, status: :unprocessable_content }
      format.html do
        assign_item_page(item)
        render 'items/show', status: :unprocessable_content
      end
    end
  end

  # Sets what items/show and the layout's breadcrumb need, as ItemsController#show does.
  #
  # @param item [Item] the item to display
  # @return [void]
  def assign_item_page(item)
    @item = item
    assign_neighbours(item.advent_calendar_item)
    assign_breadcrumb(item.advent_calendar_item)
  end

  def comment_params
    params.expect(comment: %i[user_name body item_id])
  end
end
