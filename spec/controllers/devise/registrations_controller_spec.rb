# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController do # rubocop:disable RSpec/SpecFilePathFormat
  let(:user) { create(:user) }

  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe 'GET #new' do
    render_views

    it 'keeps rendering the shared Devise sign-up view', :aggregate_failures do
      get :new
      expect(response).to have_http_status(:success)
      expect(response.body).to include('devise-bs')
    end
  end

  describe 'GET #edit' do
    context 'when rendering the view' do
      render_views
      before { sign_in user }

      it 'returns http success' do
        get :edit
        expect(response).to have_http_status(:success)
      end

      it 'renders the theme controller with the current selection' do # rubocop:disable RSpec/MultipleExpectations
        get :edit
        expect(response.body).to include('data-controller="theme"')
        system_radio = response.body[/<input[^>]*id="theme_system"[^>]*>/]
        expect(system_radio).to include('checked="checked"')
      end

      it 'passes the theme update path as a Stimulus value instead of hardcoding it in JS' do
        get :edit
        expect(response.body).to include("data-theme-path-value=\"#{theme_path}\"")
      end

      it 'associates the theme radio group with its heading for assistive technology' do
        get :edit
        expect(response.body).to match(%r{<fieldset[^>]*>.*<legend[^>]*>.*</legend>.*theme_light.*</fieldset>}m)
      end
    end
  end

  describe 'POST #create rate limit' do
    render_views

    # Posts a registration for the nth candidate user.
    #
    # @param index [Integer] distinguishes the submitted name and address
    # @return [void]
    def register(index)
      post_registration(name: "newuser#{index}", email: "newuser#{index}@example.com", password: 'password123',
                        password_confirmation: 'password123')
    end

    # Posts a registration that fails validation.
    #
    # @return [void]
    def register_invalid
      post_registration(email: 'bad', password: 'x', password_confirmation: 'y')
    end

    # Posts the given registration attributes as a visitor who is not signed in.
    #
    # @param attributes [Hash] the submitted user attributes
    # @return [void]
    def post_registration(attributes)
      sign_out :user
      post :create, params: { user: attributes }
    end

    it 'rejects the sixth sign-up from one connection with 429 and creates no account', :aggregate_failures do
      5.times { |n| register(n) }
      expect { register(5) }.not_to(change(User, :count))
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
    end

    it 'keeps signing the user in while under the limit', :aggregate_failures do
      expect { register(0) }.to change(User, :count).by(1)
      expect(response).to have_http_status(:see_other).or have_http_status(:found)
      expect(controller.current_user).to be_present
    end

    it 'counts sign-ups that fail validation as attempts', :aggregate_failures do
      5.times { register_invalid }
      expect(response).to have_http_status(:unprocessable_content)
      register_invalid
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'accepts sign-ups again after an hour' do
      6.times { |n| register(n) }
      travel(1.hour + 1.second) { expect { register(10) }.to change(User, :count).by(1) }
    end

    it 'does not affect another connection', :aggregate_failures do
      5.times { |n| register(n) }
      request.remote_addr = '10.4.0.1'
      expect { register(20) }.to change(User, :count).by(1)
    end

    it 'does not limit showing the sign-up form' do
      10.times { get :new }
      expect(response).to have_http_status(:success)
    end

    it 'does not limit account updates' do
      sign_in user
      10.times { put :update, params: { user: { name: 'renamed', current_password: user.password } } }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'does not limit account deletion' do
      sign_in user
      expect { delete :destroy }.to change(User, :count).by(-1)
    end

    it 'registers without a limit when the counter store fails' do
      allow(Rails.cache).to receive(:increment).and_return(nil)
      expect { 7.times { |n| register(n) } }.to change(User, :count).by(7)
    end
  end
end
