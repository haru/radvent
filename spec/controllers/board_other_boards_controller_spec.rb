# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoardOtherBoardsController do
  let(:owner) { create(:user) }
  let(:viewer_board) { create(:board, :public_user, owner: owner, created_at: Time.zone.local(2014, 1, 1)) }

  def create_boards(count, created_at: Time.zone.local(2015, 11, 1))
    count.times.map { create(:board, :public_user, owner: owner, created_at: created_at) }
  end

  before do
    allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))
  end

  describe 'GET #index' do
    context 'with more than two pages of boards' do
      let!(:first_page_boards) do
        create_list(:board, 10, :public_user, owner: owner, created_at: Time.zone.local(2015, 11, 1))
      end
      let!(:second_page_boards) do
        create_list(:board, 10, :public_user, owner: owner, created_at: Time.zone.local(2015, 1, 1))
      end

      it 'returns the next 10 boards for page 2' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(assigns(:other_boards)).to eq(second_page_boards)
      end

      it 'excludes the boards already shown on page 1' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(assigns(:other_boards)).not_to include(*first_page_boards)
      end

      it 'excludes the reference board' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(assigns(:other_boards)).not_to include(viewer_board)
      end
    end

    context 'when fewer than 10 boards remain' do
      before { create_boards(12) }

      it 'returns only the remaining boards' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(assigns(:other_boards).size).to eq(2)
      end
    end

    context 'when a listed board is not visible to the viewer' do
      before { create(:board, :private_user, owner: owner) }

      it 'excludes the invisible board' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(assigns(:other_boards)).to be_empty
      end
    end

    context 'when unauthenticated' do
      it 'allows fetching the listing for a public board' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when the board does not exist' do
      it 'returns 404' do
        get :index, params: { board_ref_id: 999_999, page: 2 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the board is not visible to the viewer' do
      it 'returns 404' do
        private_board = create(:board, :private_user, owner: owner)
        get :index, params: { board_ref_id: private_board.id, page: 2 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when page is less than 2' do
      it 'returns 422' do
        get :index, params: { board_ref_id: viewer_board.id, page: 1 }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when page is not an integer' do
      it 'returns 422' do
        get :index, params: { board_ref_id: viewer_board.id, page: 'abc' }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when page is missing' do
      it 'returns 422' do
        get :index, params: { board_ref_id: viewer_board.id }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when page is an enormous number beyond any possible offset' do
      before { get :index, params: { board_ref_id: viewer_board.id, page: '999999999999999999999999999999' } }

      it 'returns success instead of raising' do
        expect(response).to have_http_status(:success)
      end

      it 'returns an empty listing' do
        expect(assigns(:other_boards)).to eq([])
      end
    end

    context 'with rendering and unshown boards remaining' do
      render_views

      before { create_boards(21) }

      it 'includes the load more link' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(response.body).to include(I18n.t('boards.show.other_boards.load_more'))
      end

      it 'links to the next page' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(response.body).to include('?page=3')
      end

      it 'renders the load more link as a button' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        button = response.parsed_body.at_css('.other-boards-more a.btn')
        expect(button.text.strip).to include(I18n.t('boards.show.other_boards.load_more'))
      end

      it 'wraps the response in a turbo-frame matching the requested page, not a fixed id' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(response.parsed_body.at_css('turbo-frame#other-boards-page-2')).to be_present
      end

      it 'does not emit a nested turbo-frame with a duplicate id' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        frame_ids = response.parsed_body.css('turbo-frame').pluck('id')
        expect(frame_ids.uniq.size).to eq(frame_ids.size)
      end
    end

    context 'with rendering when all boards are shown' do
      render_views

      before { create_boards(15) }

      it 'does not include the load more link' do
        get :index, params: { board_ref_id: viewer_board.id, page: 2 }
        expect(response.body).not_to include(I18n.t('boards.show.other_boards.load_more'))
      end
    end
  end
end
