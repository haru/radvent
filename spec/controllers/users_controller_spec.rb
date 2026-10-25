# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController do
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

  describe 'GET #edit_info authorization' do
    render_views

    let(:target_user) { create(:user, email: 'target@example.com', name: 'targetuser') }
    let(:requested_id) { target_user.id }

    before { target_user }

    shared_examples 'a forbidden page without user info' do
      before { get :edit_info, params: { id: requested_id } }

      it 'responds with 403 without exposing the email address or name', :aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include('target@example.com', 'targetuser')
      end
    end

    context 'when not signed in' do
      before { sign_out user }

      it_behaves_like 'a forbidden page without user info'
    end

    context 'when a non-admin user opens another user' do
      before { sign_in create(:user) }

      it_behaves_like 'a forbidden page without user info'
    end

    context 'when a non-admin user opens own account' do
      let(:non_admin) { create(:user) }
      let(:requested_id) { non_admin.id }

      before { sign_in non_admin }

      it_behaves_like 'a forbidden page without user info'
    end

    context 'when a non-admin user opens a non-existent id' do
      let(:requested_id) { User.maximum(:id).to_i + 1 }

      before { sign_in create(:user) }

      it_behaves_like 'a forbidden page without user info'
    end

    context 'when signed in as admin' do
      before { get :edit_info, params: { id: target_user.id } }

      it 'responds with success showing the email address and name', :aggregate_failures do
        expect(response).to have_http_status(:success)
        expect(response.body).to include('target@example.com', 'targetuser')
      end
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

    context 'when the update fails' do
      render_views

      before { put :update_info, params: { id: other_user, user: { email: 'not-an-email' } } }

      it 'answers 422 so Turbo accepts the page', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_content)
        expect(other_user.reload.email).not_to eq 'not-an-email'
      end

      it 'renders it in the admin layout with the error message', :aggregate_failures do
        expect(response).to render_template(layout: 'admin')
        expect(assigns(:menu)).to eq :users
        page = Capybara.string(response.body)
        expect(page).to have_css('.invalid-feedback, .alert-danger')
      end
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
