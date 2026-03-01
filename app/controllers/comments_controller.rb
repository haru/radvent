# frozen_string_literal: true

# Manages comments on articles.
#
# Handles creating and deleting comments on items.
class CommentsController < ApplicationController
  # Creates a new comment on an item.
  #
  # @return [void]
  def create
    Comment.create(comment_params)
    redirect_to item_path(comment_params[:item_id])
  end

  # Deletes a comment.
  #
  # @return [void]
  def destroy
    @comment = Comment.find(params[:id])
    item_id = @comment.item_id
    @comment.destroy!
    redirect_to item_path(item_id)
  end

  private

  def comment_params
    params.expect(comment: %i[user_name body item_id])
  end
end
