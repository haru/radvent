# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe 'theme' do
    it 'defaults to system for a newly created user' do
      user = create(:user)
      expect(user.theme).to eq('system')
    end

    it 'only allows system, light, or dark' do
      user = create(:user)
      expect { user.theme = 'invalid' }.to raise_error(ArgumentError)
    end
  end
end
