# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Settings navigation', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin_user) { create(:user, admin: true) }

  before do
    sign_in admin_user
  end

  context 'when viewing application layout (admin menu)' do
    it 'contains user management settings link' do
      get root_path
      expect(response.body).to include('/users')
    end
  end
end
