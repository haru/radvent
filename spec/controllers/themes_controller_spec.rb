# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThemesController do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'PATCH update' do
    it 'saves a valid theme and returns it as json' do # rubocop:disable RSpec/MultipleExpectations
      patch :update, params: { theme: 'light' }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('theme' => 'light')
      expect(user.reload.theme).to eq('light')
    end

    it 'rejects an invalid theme' do # rubocop:disable RSpec/MultipleExpectations
      patch :update, params: { theme: 'invalid' }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq('error' => 'invalid theme')
    end

    context 'when persisting the theme change' do
      it 'persists the theme to the database, not just the in-memory instance' do
        patch :update, params: { theme: 'dark' }
        expect(User.find(user.id).theme).to eq('dark')
      end
    end

    context 'when the save fails' do
      before do
        allow_any_instance_of(User).to receive(:update).and_return(false)
      end

      it 'does not respond with success' do # rubocop:disable RSpec/MultipleExpectations
        patch :update, params: { theme: 'dark' }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).not_to eq('theme' => 'dark')
      end
    end

    context 'when not signed in' do
      before { sign_out user }

      it 'redirects instead of updating the theme' do
        patch :update, params: { theme: 'light' }
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
