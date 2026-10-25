# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController do
  render_views

  controller do
    def index
      render_too_many_requests
    end
  end

  describe '#render_too_many_requests' do
    before do
      allow(Rails.logger).to receive(:warn)
      get :index, params: { user: { email: 'victim@example.com', password: 'secret-password' } }
    end

    it 'responds with 429 Too Many Requests' do
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'renders the too many requests error page', :aggregate_failures do
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
      expect(response.body).to include(I18n.t('errors.too_many_requests.message'))
    end

    it 'logs the rejected controller and action at warn level' do
      expect(Rails.logger).to have_received(:warn).with('Rate limit exceeded: anonymous#index')
    end

    it 'never logs the submitted address or password', :aggregate_failures do
      expect(Rails.logger).not_to have_received(:warn).with(a_string_including('victim@example.com'))
      expect(Rails.logger).not_to have_received(:warn).with(a_string_including('secret-password'))
    end
  end
end
