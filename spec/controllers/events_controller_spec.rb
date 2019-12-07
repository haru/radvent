require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  before do
    @user = create(:user, admin: true)
    sign_in @user
    @event = create(:event, name: 'hogehoge', title: 'foobar', start_date: '2016-12-01', end_date: '2016-12-30', created_by: @user, updated_by: @user)
  end
  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    it 'returns http success' do
      post :create, params: { event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa', description: 'description' } }
      expect(response).to have_http_status(:redirect)
    end

    it 'returns 403 if user is not admin' do
      user = create(:user)
      sign_in user
      post :create, params: { event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa', description: 'description' } }
      expect(response).to have_http_status(403)
    end
  end

  describe 'PUT #update' do
    it 'returns http success' do
      put :update, params: { id: @event.id, event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa', description: 'description' } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'DELETE #destroy' do
    it 'returns http success' do
      delete :destroy, params: { id: @event.id }
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
      get :show, params: { name: @event.name }
      expect(response).to have_http_status(:success)
    end
  end
end
