# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user, admin: true) }

  before { sign_in user }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #edit_info' do
    it 'assigns @menu as :users' do
      get :edit_info, params: { id: user }
      expect(assigns(:menu)).to eq :users
    end

    it 'renders the :edit_info template' do
      get :edit_info, params: { id: user }
      expect(response).to render_template :edit_info
    end
  end

  describe 'PUT #update_info' do
    let(:other_user) { create(:user, admin: false) }

    context 'with valid params' do
      before do
        put :update_info, params: { id: other_user, user: { email: 'aaa@bbb.com' }, name: 'newname', admin: true }
      end

      it 'assigns @user as requested user' do
        expect(assigns(:user).id).to eq other_user.id
      end

      it 'updates email' do
        expect(assigns(:user).email).to eq 'aaa@bbb.com'
      end

      it 'does not grant admin status' do
        expect(assigns(:user).admin).to be false
      end

      it 'redirects to edit_user_path' do
        expect(response).to redirect_to edit_user_path(id: other_user)
      end
    end

    it 'renders the :edit_info template when update fails' do
      put :update_info, params: { id: other_user, user: { email: '' }, name: '', admin: true }
      expect(response).to render_template :edit_info
    end
  end

  describe 'delete #destroy' do
    it 'delete requested user' do
      other_user = create(:user, admin: false)
      delete :destroy, params: { id: other_user }
      expect(User.find_by(id: other_user.id)).to be_nil
    end

    it 'redirect to users_path' do
      other_user = create(:user, admin: false)
      delete :destroy, params: { id: other_user }
      expect(response).to redirect_to users_path
    end
  end
end
