# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Devise::SessionsController do
  let(:user) { create(:user, email: 'login@example.com', password: 'hogehoge') }

  before do
    user
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  # Posts a sign-in request and returns the guidance shown to the visitor.
  #
  # @param email [String] the submitted address
  # @param password [String] the submitted password
  # @return [Array] the HTTP status and the flash alert
  def failed_sign_in(email, password)
    post :create, params: { user: { email: email, password: password } }
    [response.status, flash[:alert] || response.body]
  end

  describe 'POST #create with bad credentials' do
    it 'gives the same guidance for an unknown address and a wrong password' do
      unknown = failed_sign_in('nobody@example.com', 'hogehoge')
      wrong_password = failed_sign_in('login@example.com', 'not-the-password')
      expect(unknown).to eq(wrong_password)
    end

    it 'does not sign the visitor in' do
      failed_sign_in('login@example.com', 'not-the-password')
      expect(controller.current_user).to be_nil
    end
  end
end
