# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardsController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:board) { create(:board, :public_user, owner: owner) }

  describe 'GET #index' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in owner }

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET #new' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in owner }

      it 'returns http success' do
        get :new
        expect(response).to have_http_status(:success)
      end

      context 'with rendered views' do
        render_views

        it 'renders visibility radio buttons for all three options' do
          get :new
          expect(response.body).to include('value="public"')
          expect(response.body).to include('value="protected"')
          expect(response.body).to include('value="private"')
        end

        it 'renders visibility labels without translation missing errors' do
          get :new
          expect(response.body).not_to include('translation missing')
        end
      end
    end
  end

  describe 'POST #create' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        post :create, params: { board: { board_id: 'test-board', name: 'Test', visibility: 'public' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in owner }

      it 'creates a board and redirects' do
        post :create, params: { board: { board_id: 'my-new-board', name: 'My Board', visibility: 'public' } }
        expect(response).to have_http_status(:redirect)
        expect(Board.find_by(board_id: 'my-new-board')).to be_present
      end

      it 'renders new with unprocessable content on invalid params' do
        post :create, params: { board: { board_id: '', name: '', visibility: 'public' } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'renders new with unprocessable content on duplicate board_id' do
        board
        post :create, params: { board: { board_id: board.board_id, name: 'Another', visibility: 'public' } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET #show' do
    context 'Public Board' do
      let(:board) { create(:board, :public_user, owner: owner) }

      it 'returns http success for unauthenticated user' do
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end

      it 'returns http success for authenticated non-member' do
        sign_in other_user
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'Protected Board' do
      let(:board) { create(:board, :protected_user, owner: owner) }

      it 'returns http success for unauthenticated user' do
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'Private Board' do
      let(:board) { create(:board, :private_user, owner: owner) }

      it 'returns 404 for unauthenticated user' do
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for authenticated non-member' do
        sign_in other_user
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns http success for owner' do
        sign_in owner
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end

      it 'returns http success for admin' do
        sign_in admin
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end

      it 'returns http success for member' do
        member = create(:user)
        create(:board_membership, board: board, user: member)
        sign_in member
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end

    it 'returns 404 for non-existent board_id' do
      get :show, params: { board_id: 'does-not-exist' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #edit' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get :edit, params: { board_id: board.board_id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        get :edit, params: { board_id: board.board_id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'returns http success' do
        get :edit, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'returns http success' do
        get :edit, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'updates and redirects' do
        patch :update, params: { board_id: board.board_id, board: { name: 'Updated Name' } }
        expect(response).to have_http_status(:redirect)
        expect(board.reload.name).to eq('Updated Name')
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        patch :update, params: { board_id: board.board_id, board: { name: 'Hacked' } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when authenticated as owner' do
      before { sign_in owner }

      it 'deletes the board and redirects' do
        delete :destroy, params: { board_id: board.board_id }
        expect(response).to have_http_status(:redirect)
        expect(Board.find_by(board_id: board.board_id)).to be_nil
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        delete :destroy, params: { board_id: board.board_id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'deletes the board and redirects' do
        delete :destroy, params: { board_id: board.board_id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
