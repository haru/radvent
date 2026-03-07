# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardMembershipsController, type: :controller do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:board) { create(:board, :protected_user, owner: owner) }

  describe 'GET #index' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as owner' do
      render_views
      before { sign_in owner }

      it 'returns http success' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end

      it 'renders datatable controller on the memberships table' do
        get :index, params: { board_board_id: board.board_id }
        expect(response.body).to include('data-controller="datatable"')
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get :index, params: { board_board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST #create' do
    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'redirects after adding member by email' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.email }
        expect(response).to have_http_status(:redirect)
      end

      it 'adds member by email' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.email }
        expect(board.members.reload).to include(other_user)
      end

      it 'redirects after adding member by name' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.name }
        expect(response).to have_http_status(:redirect)
      end

      it 'adds member by name' do
        post :create, params: { board_board_id: board.board_id, member_query: other_user.name }
        expect(board.members.reload).to include(other_user)
      end

      it 'shows error flash when user not found' do
        post :create, params: { board_board_id: board.board_id, member_query: 'nonexistent@example.com' }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'shows error when user is already a member' do
        create(:board_membership, board: board, user: other_user)
        post :create, params: { board_board_id: board.board_id, member_query: other_user.email }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        post :create, params: { board_board_id: board.board_id, member_query: 'someone@example.com' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:membership) { create(:board_membership, board: board, user: other_user) }

    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'redirects after removing member' do
        delete :destroy, params: { id: membership.id }
        expect(response).to have_http_status(:redirect)
      end

      it 'removes the membership' do
        delete :destroy, params: { id: membership.id }
        expect(BoardMembership.find_by(id: membership.id)).to be_nil
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in create(:user) }

      it 'returns 403' do
        delete :destroy, params: { id: membership.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'removes member and redirects' do
        delete :destroy, params: { id: membership.id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
