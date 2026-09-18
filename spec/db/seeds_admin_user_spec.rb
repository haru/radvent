# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  context 'when no users exist' do
    it 'creates a default admin user' do # rubocop:disable RSpec/MultipleExpectations
      load Rails.root.join('db/seeds.rb')

      admin = User.find_by(email: 'admin@example.com')
      expect(admin).to be_present
      expect(admin.admin?).to be true
    end
  end

  context 'when a user already exists' do
    before { create(:user) }

    it 'does not create the default admin user' do
      load Rails.root.join('db/seeds.rb')

      expect(User.where(email: 'admin@example.com')).not_to exist
    end
  end
end
