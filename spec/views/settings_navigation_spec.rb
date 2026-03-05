# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings navigation', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin_user) { create(:user, admin: true) }

  before do
    sign_in admin_user
  end

  context 'when viewing admin layout navigation' do
    it 'does not contain events list navigation link' do
      get events_list_path
      expect(response.body).not_to include('/admin/events')
    end
  end

  context 'when viewing application layout (admin menu)' do
    it 'does not contain events list settings link' do
      get root_path
      expect(response.body).not_to include('/admin/events')
    end
  end
end
