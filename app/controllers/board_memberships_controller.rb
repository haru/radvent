# frozen_string_literal: true

# Manages board member management.
#
# Handles adding and removing members from UserBoards.
class BoardMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_board, only: %i[index create search]
  before_action :check_editability, only: %i[index create search]
  before_action :find_membership, only: [:destroy]
  before_action :check_membership_deletability, only: [:destroy]
  # Declared after the permission checks so rejected requests are not counted. Per user, not per IP.
  rate_limit to: 60, within: 1.minute, only: :search, by: -> { current_user.id }, with: :render_too_many_requests

  # Shortest search term (after stripping) that triggers a search.
  MIN_QUERY_LENGTH = 2

  # Longest search term accepted; matches the length of the users columns.
  MAX_QUERY_LENGTH = 255

  # Lists all members of the board.
  # @return [void]
  def index
    @memberships = @board.board_memberships.includes(:user)
  end

  # Returns candidate users for the member form as an HTML fragment.
  # Responds with 204 when the term is shorter than MIN_QUERY_LENGTH and with 400 when it is not a
  # string or longer than MAX_QUERY_LENGTH.
  # @return [void]
  def search
    raw = params[:member_query]
    return head :bad_request unless raw.nil? || raw.is_a?(String)

    query = raw.to_s.strip
    return head :bad_request if query.length > MAX_QUERY_LENGTH
    return head :no_content if query.length < MIN_QUERY_LENGTH

    users, more = @board.member_candidates(query)
    no_store
    render partial: 'search_results', locals: { users: users, more: more }
  end

  # Adds a new member, identified by the picked candidate's user_id or else by exact email or name.
  # @return [void]
  def create
    user = find_user
    return handle_user_not_found if user.nil?
    return handle_user_not_found(:ambiguous_name) if user == :ambiguous

    membership = BoardMembership.new(board: @board, user: user)
    save_membership(membership)
  end

  # Removes a member from the board.
  # @return [void]
  def destroy
    @membership.destroy
    redirect_to board_board_memberships_path(@membership.board.board_id), status: :see_other,
                                                                          notice: t('board_memberships.member_removed')
  end

  private

  def find_board
    @board = Board.find_by(board_id: params[:board_board_id])
    render_not_found unless @board
  end

  def check_editability
    render_forbidden unless @board&.editable?(current_user)
  end

  def find_membership
    @membership = BoardMembership.find_by(id: params[:id])
    render_not_found unless @membership
  end

  def check_membership_deletability
    render_forbidden unless @membership&.board&.editable?(current_user)
  end

  # A candidate picked in the search is identified by id, because names are not unique.
  # Without an id the typed text must match an email or a name exactly. Returns +:ambiguous+ when
  # several users have that name, so the wrong person is never added silently.
  def find_user
    return find_user_by_id(params[:user_id]) if params[:user_id].present?

    query = params[:member_query]
    return if !query.is_a?(String) || query.blank?

    User.find_by(email: query) || find_user_by_name(query)
  end

  def find_user_by_id(id)
    User.find_by(id: id) if id.is_a?(String) && id.match?(/\A\d+\z/)
  end

  def find_user_by_name(name)
    matches = User.where(name: name).limit(2).to_a
    matches.size > 1 ? :ambiguous : matches.first
  end

  def handle_user_not_found(error = :user_not_found)
    flash.now[:alert] = t("board_memberships.errors.#{error}")
    @memberships = @board.board_memberships.includes(:user)
    render :index, status: :unprocessable_content
  end

  def save_membership(membership)
    if membership.save
      redirect_to board_board_memberships_path(@board.board_id), notice: t('board_memberships.member_added')
    else
      flash.now[:alert] = t('board_memberships.errors.already_member')
      @memberships = @board.board_memberships.includes(:user)
      render :index, status: :unprocessable_content
    end
  end
end
