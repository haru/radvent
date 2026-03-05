# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do
  let!(:top_board) { Board.find_or_create_by!(board_type: :top) { |b| b.name = 'TOP' } }

  describe 'GET #index' do
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
  end
end
