# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardsController do
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
      render_views
      before { sign_in owner }

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'renders datatable controller on the boards table' do
        get :index
        expect(response.body).to include('data-controller="datatable"')
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
      render_views
      before { sign_in owner }

      it 'returns http success' do
        get :new
        expect(response).to have_http_status(:success)
      end

      it 'renders public visibility radio button' do
        get :new
        expect(response.body).to include('value="public"')
      end

      it 'renders protected visibility radio button' do
        get :new
        expect(response.body).to include('value="protected"')
      end

      it 'renders private visibility radio button' do
        get :new
        expect(response.body).to include('value="private"')
      end

      it 'renders visibility labels without translation missing errors' do
        get :new
        expect(response.body).not_to include('translation missing')
      end

      it 'does not render a placeholder on the board_id field' do
        get :new
        expect(response.body).not_to include('placeholder="my-board"')
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

      it 'redirects after creating a board' do
        post :create, params: { board: { board_id: 'my-new-board', name: 'My Board', visibility: 'public' } }
        expect(response).to have_http_status(:redirect)
      end

      it 'creates a board' do
        post :create, params: { board: { board_id: 'my-new-board', name: 'My Board', visibility: 'public' } }
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
    def create_boards(count, created_at: Time.zone.local(2015, 11, 1))
      count.times.map { create(:board, :public_user, owner: owner, created_at: created_at) }
    end

    context 'when the board is a public board' do
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

    context 'when the board is a protected board' do
      let(:board) { create(:board, :protected_user, owner: owner) }

      it 'returns http success for unauthenticated user' do
        get :show, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when the board is a private board' do
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

    context 'when assembling @other_boards' do
      let(:viewer_board) { create(:board, :public_user, owner: owner, created_at: Time.zone.local(2015, 10, 1)) }
      let!(:no_item_board) do
        create(:board, :public_user, owner: owner, created_at: Time.zone.local(2015, 11, 10))
      end
      let!(:unpublished_only_board) do
        create_board_with_item(created_at: Time.zone.local(2015, 11, 15),
                               item_created_at: Time.zone.local(2015, 12, 20, 0, 0, 0),
                               item_date: 25)
      end
      let!(:published_board) do
        create_board_with_item(created_at: Time.zone.local(2015, 11, 1),
                               item_created_at: Time.zone.local(2015, 12, 1, 10, 0, 0),
                               item_date: 2)
      end
      let!(:newer_board) do
        create_board_with_item(created_at: Time.zone.local(2015, 12, 5),
                               item_created_at: Time.zone.local(2015, 12, 1, 9, 0, 0))
      end

      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
      end

      def create_board_with_item(created_at:, item_created_at: nil, item_date: 1)
        other = create(:board, :public_user, owner: owner, created_at: created_at)
        if item_created_at
          event = create(:event, board: other, start_date: '2015-12-01', end_date: '2015-12-25',
                                 created_by: owner, updated_by: owner)
          calendar_item = create(:advent_calendar_item, event: event, date: item_date)
          create(:item, advent_calendar_item: calendar_item, created_at: item_created_at)
        end
        other
      end

      it 'includes visible other boards' do
        other = create(:board, :public_user, owner: owner)
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards)).to include(other)
      end

      it 'excludes the currently displayed board' do
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards)).not_to include(viewer_board)
      end

      it 'excludes a private board the viewer can neither own nor join' do
        private_board = create(:board, :private_user, owner: owner)
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards)).not_to include(private_board)
      end

      it 'includes the TOP board when viewing a user board' do
        top_board = create(:board, :top)
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards)).to include(top_board)
      end

      it 'sorts boards by their sort key descending' do
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards)).to eq(
          [newer_board, published_board, unpublished_only_board, no_item_board]
        )
      end

      it 'sorts boards with an identical sort key by id ascending' do
        first_board = create(:board, :public_user, owner: owner, created_at: Time.zone.local(2015, 11, 20))
        second_board = create(:board, :public_user, owner: owner, created_at: Time.zone.local(2015, 11, 20))
        get :show, params: { board_id: viewer_board.board_id }
        listing = assigns(:other_boards)
        expect(listing.index(first_board)).to be < listing.index(second_board)
      end

      it 'does not assign a next page number when all boards fit on one page' do
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards_next_page)).to be_nil
      end
    end

    context 'when the TOP board is listed in @other_boards' do
      render_views

      it 'labels it with the site title, not its literal board name' do
        ENV['RADVENT_TITLE'] = nil
        create(:board, :top)
        get :show, params: { board_id: board.board_id }
        link = response.parsed_body.at_css('.other-boards-list-item a[href="/"]')
        expect(link.text).to eq('Advent Calendar')
      end
    end

    context 'when more boards than the page size exist' do
      let(:viewer_board) { create(:board, :public_user, owner: owner, created_at: Time.zone.local(2015, 10, 1)) }

      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
        create_boards(11)
      end

      it 'caps @other_boards at 10 items' do
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards).size).to eq(10)
      end

      it 'assigns the total count of visible other boards' do
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards_more)).to eq(11)
      end

      it 'assigns the next page number' do
        get :show, params: { board_id: viewer_board.board_id }
        expect(assigns(:other_boards_next_page)).to eq(2)
      end
    end

    context 'when there are no other visible boards' do
      render_views

      it 'does not render the other boards heading' do
        get :show, params: { board_id: board.board_id }
        expect(response.body).not_to include(I18n.t('boards.show.other_boards.title'))
      end

      it 'does not render the other boards area markup' do
        get :show, params: { board_id: board.board_id }
        expect(response.body).not_to include('id="other-boards"')
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
      render_views
      before { sign_in owner }

      it 'returns http success' do
        get :edit, params: { board_id: board.board_id }
        expect(response).to have_http_status(:success)
      end

      it 'renders the confirmation message including the board_id' do
        get :edit, params: { board_id: board.board_id }
        expect(response.body).to include("ボードIDは #{board.board_id} です。")
      end

      it 'renders a native turbo-confirm dialog on the delete form' do
        get :edit, params: { board_id: board.board_id }
        expect(response.body).to include(%(data-turbo-confirm="#{I18n.t('boards.edit.delete_warning')}"))
      end

      it 'renders a label associated with the confirm_board_id field' do
        get :edit, params: { board_id: board.board_id }
        expect(response.body).to include('for="confirm_board_id"')
      end

      it 'does not render the delete button disabled by default' do
        get :edit, params: { board_id: board.board_id }
        expect(response.body).not_to include('disabled="disabled"')
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

      it 'redirects after update' do
        patch :update, params: { board_id: board.board_id, board: { name: 'Updated Name' } }
        expect(response).to have_http_status(:redirect)
      end

      it 'updates the board' do
        patch :update, params: { board_id: board.board_id, board: { name: 'Updated Name' } }
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

      it 'redirects to boards after deleting the board' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: board.board_id }
        expect(response).to redirect_to(boards_path)
      end

      it 'responds with See Other when the board is deleted' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: board.board_id }
        expect(response).to have_http_status(:see_other)
      end

      it 'deletes the board when confirm_board_id matches' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: board.board_id }
        expect(Board.find_by(board_id: board.board_id)).to be_nil
      end

      it 'deletes the board when confirm_board_id differs only in case or whitespace' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: " #{board.board_id.upcase} " }
        expect(Board.find_by(board_id: board.board_id)).to be_nil
      end
    end

    context 'when confirm_board_id does not match' do
      before { sign_in owner }

      it 'does not delete the board on a wrong value' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: 'wrong-id' }
        expect(Board.find_by(board_id: board.board_id)).to be_present
      end

      it 'does not delete the board on an empty value' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: '' }
        expect(Board.find_by(board_id: board.board_id)).to be_present
      end

      it 'does not delete the board when confirm_board_id is omitted' do
        delete :destroy, params: { board_id: board.board_id }
        expect(Board.find_by(board_id: board.board_id)).to be_present
      end

      it 'redirects back to edit' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: 'wrong-id' }
        expect(response).to redirect_to(edit_board_path(board.board_id))
      end

      it 'responds with See Other when the board ID does not match' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: 'wrong-id' }
        expect(response).to have_http_status(:see_other)
      end

      it 'sets a mismatch alert' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: 'wrong-id' }
        expect(flash[:alert]).to eq(I18n.t('boards.edit.delete_id_mismatch'))
      end
    end

    context 'when authenticated as non-owner' do
      before { sign_in other_user }

      it 'returns 403' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: board.board_id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      before { sign_in admin }

      it 'deletes the board and redirects' do
        delete :destroy, params: { board_id: board.board_id, confirm_board_id: board.board_id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
