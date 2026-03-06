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

    it 'assigns @event as a new Event' do
      get :new
      expect(assigns(:event)).to be_a(Event)
    end

    it 'assigns @event as a new record' do
      get :new
      expect(assigns(:event)).to be_new_record
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
          params: { name: event.name,
                    event: { title: 'test', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                             description: 'description' } }
      expect(response).to have_http_status(:redirect)
    end

    it 'redirects to event view after successful update' do
      put :update,
          params: { name: event.name,
                    event: { title: 'updated', start_date: '2017-12-01', end_date: '2017-12-25', name: 'aaa',
                             description: 'description' } }
      expect(response).to redirect_to(show_event_path('aaa'))
    end
  end

  describe 'check_edit_permission' do
    let(:event_owner) { create(:user) }
    let(:admin_user) { create(:user, admin: true) }
    let(:other_user) { create(:user) }
    let(:owned_event) do
      create(:event, name: 'owned-event', title: 'Owned Event', start_date: '2016-12-01', end_date: '2016-12-25',
                     created_by: event_owner, updated_by: event_owner)
    end

    before do
      owned_event
    end

    context 'when user is event owner' do
      before { sign_in event_owner }

      it 'allows access to edit action' do
        get :edit, params: { name: owned_event.name }
        expect(response).not_to have_http_status(403)
      end

      it 'allows access to update action' do
        put :update, params: { name: owned_event.name, event: { title: 'test' } }
        expect(response).not_to have_http_status(403)
      end

      it 'allows access to destroy action' do
        delete :destroy, params: { name: owned_event.name }
        expect(response).not_to have_http_status(403)
      end
    end

    context 'when user is admin' do
      before { sign_in admin_user }

      it 'allows access to edit action' do
        get :edit, params: { name: owned_event.name }
        expect(response).not_to have_http_status(403)
      end

      it 'allows access to update action' do
        put :update, params: { name: owned_event.name, event: { title: 'test' } }
        expect(response).not_to have_http_status(403)
      end

      it 'allows access to destroy action' do
        delete :destroy, params: { name: owned_event.name }
        expect(response).not_to have_http_status(403)
      end
    end

    context 'when user is not event owner and not admin' do
      before { sign_in other_user }

      it 'denies access to edit action' do
        get :edit, params: { name: owned_event.name }
        expect(response).to have_http_status(403)
      end

      it 'denies access to update action' do
        put :update, params: { name: owned_event.name, event: { title: 'test' } }
        expect(response).to have_http_status(403)
      end

      it 'denies access to destroy action' do
        delete :destroy, params: { name: owned_event.name }
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'returns http success' do
      delete :destroy, params: { name: event.name }
      expect(response).to have_http_status(:redirect)
    end

    it 'redirects to board page after successful destroy' do
      delete :destroy, params: { name: event.name }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { name: event.name }
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
      put :update, params: { name: event.name, event: { title: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST #create on UserBoard' do
    let(:board_owner) { create(:user) }
    let(:public_board) { create(:board, :public_user, owner: board_owner) }
    let(:protected_board) { create(:board, :protected_user, owner: board_owner) }
    let(:non_member) { create(:user) }

    context 'when user is authenticated on a Public Board' do
      before { sign_in non_member }

      it 'allows authenticated non-member to create event' do
        post :create, params: {
          event: { title: 'public-event', start_date: '2017-12-01', end_date: '2017-12-25',
                   name: 'public-evt', description: 'desc', board_id: public_board.id }
        }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when user is not a member of a Protected Board' do
      before { sign_in non_member }

      it 'returns 403' do
        post :create, params: {
          event: { title: 'protected-event', start_date: '2017-12-01', end_date: '2017-12-25',
                   name: 'protected-evt', description: 'desc', board_id: protected_board.id }
        }
        expect(response).to have_http_status(403)
      end
    end
  end
end
