# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:user) { create(:user, admin: true) }
  let(:event) do
    create(:event, name: 'hogehoge', title: 'foobar', start_date: '2016-12-01', end_date: '2016-12-30',
                   created_by: user, updated_by: user)
  end

  before do
    sign_in user
    event
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'returns http success' do
      post :create,
           params: { event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                              description: 'description' } }
      expect(response).to have_http_status(:redirect)
    end

    it 'returns 403 if user is not admin' do
      sign_in create(:user)
      post :create,
           params: { event: { title: 'test2', start_date: '2017-12-01', end_date: '2017-12-25', name: 'bbb',
                              description: 'description' } }
      expect(response).to have_http_status(403)
    end
  end

  describe 'PUT #update' do
    it 'returns http success' do
      put :update,
          params: { id: event.id,
                    event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                             description: 'description' } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'DELETE #destroy' do
    it 'returns http success' do
      delete :destroy, params: { id: event.id }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { name: event.name }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #list' do
    it 'returns http success' do
      get :list
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create failure' do
    it 'renders new with unprocessable content on invalid event' do
      post :create, params: { event: { title: '', start_date: '', end_date: '', name: '', description: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'PUT #update failure' do
    it 'renders edit with unprocessable content on invalid update' do
      put :update, params: { id: event.id, event: { title: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST #create on UserBoard' do
    let(:board_owner) { create(:user) }
    let(:public_board) { create(:board, :public_user, owner: board_owner) }
    let(:protected_board) { create(:board, :protected_user, owner: board_owner) }

    context 'when user is authenticated on a Public Board' do
      it 'allows authenticated non-member to create event' do
        non_member = create(:user)
        sign_in non_member
        post :create, params: {
          event: { title: 'public-event', start_date: '2017-12-01', end_date: '2017-12-25',
                   name: 'public-evt', description: 'desc', board_id: public_board.id }
        }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when user is not a member of a Protected Board' do
      it 'returns 403' do
        sign_in create(:user)
        post :create, params: {
          event: { title: 'protected-event', start_date: '2017-12-01', end_date: '2017-12-25',
                   name: 'protected-evt', description: 'desc', board_id: protected_board.id }
        }
        expect(response).to have_http_status(403)
      end
    end
  end
end
