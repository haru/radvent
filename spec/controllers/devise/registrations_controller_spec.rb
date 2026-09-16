# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Devise::RegistrationsController do
  let(:user) { create(:user) }

  before { request.env['devise.mapping'] = Devise.mappings[:user] }

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
    end
  end
end
