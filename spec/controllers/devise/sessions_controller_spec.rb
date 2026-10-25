# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController do # rubocop:disable RSpec/SpecFilePathFormat
  let(:password) { 'hogehoge' }
  let(:user) { create(:user, email: 'login@example.com', password: password) }

  before do
    user
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  # Drops the warden proxy so a halted strategy from a previous request in the
  # same example cannot short-circuit the next one, then builds a fresh one.
  #
  # ActionController::TestCase also carries the previous request's env over: the
  # leaked params-authentication flag would let the layout's +current_user+ run
  # the database strategy (and count a failed attempt) while a 429 page renders.
  #
  # @return [void]
  def fresh_warden!
    request.env.delete('warden')
    request.env.delete('devise.allow_params_authentication')
    warden
  end

  # Posts a sign-in request and returns the guidance shown to the visitor.
  #
  # @param email [String] the submitted address
  # @param password [String] the submitted password
  # @return [Array] the HTTP status and the flash alert
  def failed_sign_in(email, password)
    fresh_warden!
    post :create, params: { user: { email: email, password: password } }
    [response.status, flash[:alert] || response.body]
  end

  # Posts a sign-in request from the given connection and returns everything an
  # outsider can observe about the answer.
  #
  # @param ip [String] the address the request appears to come from
  # @param email [String] the submitted address
  # @param password [String] the submitted password
  # @return [Array] the HTTP status, the redirect target and the flash alert
  def sign_in_from(ip, email:, password:)
    fresh_warden!
    request.remote_addr = ip
    post :create, params: { user: { email: email, password: password } }
    [response.status, response.location, flash[:alert]]
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

    it 'answers with the generic invalid-credentials message' do
      _status, alert = failed_sign_in('login@example.com', 'not-the-password')
      expect(alert).to eq I18n.t('devise.failure.invalid')
    end

    it 'starts counting from zero again after a successful sign-in' do
      2.times { failed_sign_in(user.email, 'not-the-password') }
      failed_sign_in(user.email, password)
      expect(user.reload.failed_attempts).to eq 0
    end
  end

  describe 'POST #create with a locked account' do
    it 'keeps the correct password out while the account is locked', :aggregate_failures do
      10.times { failed_sign_in(user.email, 'not-the-password') }
      # Step over the per-connection limit (10 per minute); the lock lasts 15 minutes.
      # One extra second clears the whole-second truncation of `travel`.
      status, alert = travel(1.minute + 1.second) { failed_sign_in(user.email, password) }
      expect(controller.current_user).to be_nil
      expect([status, alert]).to eq([422, I18n.t('devise.failure.invalid')])
    end

    it 'lets the correct password in once the lock has timed out' do
      10.times { failed_sign_in(user.email, 'not-the-password') }
      travel(15.minutes + 1.second) { failed_sign_in(user.email, password) }
      expect(controller.current_user).to eq user
    end

    it 'does not sign out an already signed-in user when the account gets locked' do
      sign_in user
      user.lock_access!
      get :new
      expect(controller.current_user).to eq user
    end

    it 'answers locked, wrong-password and unknown addresses identically' do # rubocop:disable RSpec/ExampleLength
      locked = create(:user, email: 'locked@example.com', password: password)
      locked.lock_access!

      wrong_password = sign_in_from('10.0.0.1', email: user.email, password: 'not-the-password')
      unknown = sign_in_from('10.0.0.2', email: 'nobody@example.com', password: password)
      locked_answer = sign_in_from('10.0.0.3', email: locked.email, password: password)

      expect(locked_answer).to eq(wrong_password).and eq(unknown)
    end

    it 'answers an unknown address identically however often it fails' do
      answers = 3.times.map { |n| sign_in_from("10.1.0.#{n}", email: 'nobody@example.com', password: password) }
      expect(answers.uniq.size).to eq 1
    end

    it 'counts variants of the address as failures of the same account' do
      variants = [' LOGIN@example.com ', 'login@EXAMPLE.com', "\tlogin@example.com"]
      variants.each_with_index do |email, n|
        sign_in_from("10.2.0.#{n}", email: email, password: 'not-the-password')
      end
      expect(user.reload.failed_attempts).to eq 3
    end
  end

  describe 'POST #create per-connection limit' do
    render_views

    let(:ip) { '10.0.0.9' }

    it 'rejects the eleventh attempt from one connection with 429', :aggregate_failures do
      allow(Rails.logger).to receive(:warn)
      10.times { sign_in_from(ip, email: user.email, password: 'not-the-password') }
      sign_in_from(ip, email: user.email, password: 'not-the-password')
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
    end

    it "renders the 429 page in the request's language, whatever locale the thread holds", # rubocop:disable RSpec/ExampleLength
       :aggregate_failures do
      I18n.with_locale(:ja) do
        10.times { sign_in_from(ip, email: user.email, password: 'not-the-password') }
        request.headers['Accept-Language'] = 'en'
        sign_in_from(ip, email: user.email, password: 'not-the-password')
      end
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include(I18n.t('errors.too_many_requests.title', locale: :en))
    end

    it 'rejects without counting the attempt against the account' do
      11.times { sign_in_from(ip, email: user.email, password: 'not-the-password') }
      expect(user.reload.failed_attempts).to eq 10
    end

    it 'never logs the submitted address or password', :aggregate_failures do
      allow(Rails.logger).to receive(:warn)
      11.times { sign_in_from(ip, email: user.email, password: 'not-the-password') }
      expect(Rails.logger).to have_received(:warn).with('Rate limit exceeded: users/sessions#create')
      expect(Rails.logger).not_to have_received(:warn).with(a_string_including(user.email))
      expect(Rails.logger).not_to have_received(:warn).with(a_string_including('not-the-password'))
    end

    it 'keeps serving another connection normally at the same moment', :aggregate_failures do
      11.times { sign_in_from(ip, email: user.email, password: 'not-the-password') }
      sign_in_from('10.0.1.1', email: user.email, password: 'not-the-password')
      expect(response).not_to have_http_status(:too_many_requests)
      expect(flash[:alert]).to be_present
    end

    it 'keeps serving the same connection after the minute has passed', :aggregate_failures do
      11.times { sign_in_from(ip, email: user.email, password: 'not-the-password') }
      travel(1.minute + 1.second) { sign_in_from(ip, email: user.email, password: 'not-the-password') }
      expect(response).not_to have_http_status(:too_many_requests)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST #create when the counter store fails' do
    before { allow(Rails.cache).to receive(:increment).and_return(nil) }

    it 'processes every attempt instead of rejecting' do
      11.times { failed_sign_in(user.email, 'not-the-password') }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'still locks the account after the configured number of failures' do
      10.times { failed_sign_in(user.email, 'not-the-password') }
      expect(user.reload.access_locked?).to be true
    end
  end

  describe 'GET #new' do
    render_views

    it 'keeps rendering the shared Devise sign-in view', :aggregate_failures do
      get :new
      expect(response).to have_http_status(:success)
      expect(response.body).to include('devise-bs')
    end
  end
end
