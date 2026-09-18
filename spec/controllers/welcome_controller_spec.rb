# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WelcomeController do
  let!(:top_board) { Board.find_or_create_by!(board_type: :top) { |b| b.name = 'TOP' } }

  describe 'GET #index' do
    def create_boards(count, created_at: Time.zone.local(2015, 11, 1))
      count.times.map { create(:board, :public_user, created_at: created_at) }
    end

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @events scoped to TopBoard' do
      admin = create(:user, admin: true)
      event = create(:event, board: top_board, created_by: admin, updated_by: admin)
      get :index
      expect(assigns(:events)).to include(event)
    end

    context 'when no other boards are visible' do
      render_views

      it 'does not render the other boards heading' do
        get :index
        expect(response.body).not_to include(I18n.t('boards.show.other_boards.title'))
      end

      it 'does not render the other boards area markup' do
        get :index
        expect(response.body).not_to include('id="other-boards"')
      end
    end

    context 'when assembling @other_boards' do
      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
      end

      it 'includes visible user boards' do
        user_board = create(:board, :public_user)
        get :index
        expect(assigns(:other_boards)).to include(user_board)
      end

      it 'excludes the TOP board itself' do
        get :index
        expect(assigns(:other_boards)).not_to include(top_board)
      end

      it 'excludes private boards not visible to the viewer' do
        create(:board, :private_user)
        get :index
        expect(assigns(:other_boards)).to be_empty
      end
    end

    context 'when more boards than the page size exist' do
      before do
        allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
        create_boards(11)
      end

      it 'caps @other_boards at 10 items' do
        get :index
        expect(assigns(:other_boards).size).to eq(10)
      end

      it 'assigns the total count of visible other boards' do
        get :index
        expect(assigns(:other_boards_more)).to eq(11)
      end

      it 'assigns the next page number' do
        get :index
        expect(assigns(:other_boards_next_page)).to eq(2)
      end
    end
  end
end
