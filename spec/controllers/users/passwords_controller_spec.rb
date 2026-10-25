# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::PasswordsController do
  render_views

  let!(:user) { create(:user, email: 'registered@example.com') }
  let(:notice) { I18n.t('devise.passwords.send_paranoid_instructions') }

  around do |example|
    original = ActionMailer::Base.default_url_options
    ActionMailer::Base.default_url_options = { host: 'test.host' }
    example.run
  ensure
    ActionMailer::Base.default_url_options = original
  end

  before do
    request.env['devise.mapping'] = Devise.mappings[:user]
    ActionMailer::Base.deliveries.clear
  end

  # Posts a password reset request for the given email.
  #
  # @param email [String, nil] the submitted address
  # @return [void]
  def request_reset(email)
    post :create, params: { user: { email: email } }
  end

  # Raises the given error with a message naming the recipient, as real SMTP errors do; a template
  # error needs a cause to take it from.
  #
  # @param error [Class] the error class
  # @return [void]
  def raise_delivery_error(error)
    raise 'rejected <registered@example.com>'
  rescue StandardError
    raise error == ActionView::Template::Error ? error.new(nil) : error.new('rejected <registered@example.com>')
  end

  # Returns the parts of the response that must not differ between accounts.
  #
  # @return [Array] status, location and flash
  def observable
    [response.status, response.location, flash.to_hash]
  end

  describe 'POST #create' do
    it 'redirects a registered address with the generic notice and sends mail', :aggregate_failures do
      expect { request_reset('registered@example.com') }.to change { ActionMailer::Base.deliveries.size }.by(1)
      expect(response).to redirect_to(new_user_session_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq notice
    end

    it 'answers an unregistered address the same way without sending mail', :aggregate_failures do
      expect { request_reset('nobody@example.com') }.not_to(change { ActionMailer::Base.deliveries.size })
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to eq notice
      expect(response.body).not_to include(I18n.t('errors.messages.not_found'))
    end

    [Net::SMTPFatalError, Errno::ECONNREFUSED, ActionView::Template::Error].each do |error|
      context "when delivery fails with #{error}" do
        before do
          allow(Rails.logger).to receive(:error)
          allow(Rails.error).to receive(:report)
          allow(Devise::Mailer).to receive(:reset_password_instructions) { raise_delivery_error(error) }
          request_reset('registered@example.com')
        end

        it 'answers like a success', :aggregate_failures do
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:notice]).to eq notice
        end

        it 'logs the class only' do
          expect(Rails.logger).to have_received(:error).with(a_string_including(error.name))
        end

        it 'does not log the address or the error message' do
          expect(Rails.logger).not_to have_received(:error).with(a_string_including('registered@', 'rejected'))
        end

        it 'reports the error as handled' do
          expect(Rails.error).to have_received(:report).with(an_instance_of(error), hash_including(handled: true))
        end
      end
    end

    it 'responds identically for registered, unregistered and failed delivery' do
      outcomes = %w[registered@example.com nobody@example.com].map { |email| request_reset(email) && observable }
      allow(Devise::Mailer).to receive(:reset_password_instructions).and_raise(Net::SMTPFatalError, 'x')
      outcomes << (request_reset('registered@example.com') && observable)
      expect(outcomes.uniq.size).to eq 1
    end

    [nil, ''].each do |value|
      it "responds 422 with a blank error for #{value.inspect} and sends nothing", :aggregate_failures do
        expect { request_reset(value) }.not_to(change { ActionMailer::Base.deliveries.size })
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t('errors.messages.blank'))
      end
    end

    ['abc', 'a@', 'a b@example.com'].each do |value|
      it "responds 422 with an invalid error for #{value.inspect} and sends nothing", :aggregate_failures do
        expect { request_reset(value) }.not_to(change { ActionMailer::Base.deliveries.size })
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t('errors.messages.invalid'))
      end
    end

    it 'does not swallow errors raised before delivery, such as a database failure' do
      allow(User).to receive(:find_by).and_raise(ActiveRecord::ConnectionNotEstablished)
      expect { request_reset('registered@example.com') }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end

    it 'normalizes case and surrounding whitespace like sign-in', :aggregate_failures do
      expect { request_reset(' REGISTERED@Example.COM ') }.to change { ActionMailer::Base.deliveries.size }.by(1)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'POST #create per-address mail limit' do
    it 'sends the mail only for the first request within five minutes', :aggregate_failures do
      request_reset('registered@example.com')
      expect { request_reset('registered@example.com') }.not_to(change { ActionMailer::Base.deliveries.size })
      expect(ActionMailer::Base.deliveries.size).to eq 1
    end

    it 'answers registered, limited and unregistered addresses identically' do
      outcomes = []
      outcomes << (request_reset('registered@example.com') && observable)
      outcomes << (request_reset('registered@example.com') && observable)
      outcomes << (request_reset('nobody@example.com') && observable)
      expect(outcomes.uniq.size).to eq 1
    end

    it 'sends the mail again once the five minutes have passed' do
      request_reset('registered@example.com')
      travel(5.minutes + 1.second) { request_reset('registered@example.com') }
      expect(ActionMailer::Base.deliveries.size).to eq 2
    end

    it 'counts whitespace and case variants as the same single slot', :aggregate_failures do
      request_reset(' REGISTERED@Example.COM ')
      expect { request_reset('registered@example.com') }.not_to(change { ActionMailer::Base.deliveries.size })
      expect(ActionMailer::Base.deliveries.size).to eq 1
    end

    it 'does not spend the address slot on a blank or malformed address', :aggregate_failures do
      request_reset(nil)
      request_reset('abc')
      expect(ActionMailer::Base.deliveries.size).to eq 0
      expect { request_reset('registered@example.com') }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it 'hashes the address into the cache key instead of storing it in plain text', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      keys = []
      allow(Rails.cache).to receive(:increment).and_wrap_original do |original, key, *args, **options|
        keys << key
        original.call(key, *args, **options)
      end
      request_reset('registered@example.com')
      key = keys.find { |k| k.to_s.start_with?('password-reset-mail:') }
      expect(key).to match(/\Apassword-reset-mail:[0-9a-f]{64}\z/)
      expect(key).not_to include('registered@example.com')
    end

    it 'logs a suppressed mail for a registered address without naming it', :aggregate_failures do
      allow(Rails.logger).to receive(:info)
      request_reset('registered@example.com')
      request_reset('registered@example.com')
      expect(Rails.logger).to have_received(:info).with('Password reset mail suppressed: per-address limit').once
    end

    it 'logs nothing about suppression for an unregistered address' do
      allow(Rails.logger).to receive(:info)
      2.times { request_reset('nobody@example.com') }
      expect(Rails.logger).not_to have_received(:info).with(a_string_including('suppressed'))
    end

    it 'still sends the mail when the counter store fails' do
      allow(Rails.cache).to receive(:increment).and_return(nil)
      expect { request_reset('registered@example.com') }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  describe 'POST #create per-connection limit' do
    render_views

    it 'rejects the sixth request from one connection with 429 however the addresses are registered', # rubocop:disable RSpec/ExampleLength
       :aggregate_failures do
      request.remote_addr = '10.3.0.1'
      5.times { request_reset('registered@example.com') }
      request_reset('registered@example.com')
      registered = [response.status, response.body]

      request.remote_addr = '10.3.0.2'
      5.times { |n| request_reset("nobody#{n}@example.com") }
      request_reset('nobody@example.com')

      expect(response).to have_http_status(:too_many_requests)
      expect([response.status, response.body]).to eq registered
      expect(response.body).to include(I18n.t('errors.too_many_requests.title'))
    end

    it 'sends no mail for a rejected request and does not spend the address slot', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      counts = Hash.new(0)
      allow(Rails.cache).to receive(:increment).and_wrap_original do |original, key, *args, **options|
        counts[key] += 1 if key.to_s.start_with?('password-reset-mail:')
        original.call(key, *args, **options)
      end
      6.times { request_reset('registered@example.com') }
      expect(ActionMailer::Base.deliveries.size).to eq 1
      expect(counts.values.sum).to eq 5
    end
  end

  describe 'POST #create per-connection limit window' do
    it 'accepts requests from the same connection again after an hour', :aggregate_failures do
      6.times { request_reset('registered@example.com') }
      travel(1.hour + 1.second) { request_reset('other@example.com') }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'keeps serving another connection at the same moment' do
      6.times { request_reset('registered@example.com') }
      request.remote_addr = '10.3.0.9'
      5.times { |n| request_reset("nobody#{n}@example.com") }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it 'rejects an unregistered address over the limit exactly like a registered one' do
      6.times { request_reset('nobody@example.com') }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'unlockable?' do
    it 'is not routable as an action' do
      expect(described_class.action_methods).not_to include('unlockable?')
    end
  end

  describe 'GET #new' do
    it 'renders the form' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT #update' do
    it 'resets the password with a valid token', :aggregate_failures do
      token = user.send_reset_password_instructions
      put :update, params: { user: { reset_password_token: token, password: 'newpassword1',
                                     password_confirmation: 'newpassword1' } }
      expect(response).to have_http_status(:see_other)
      expect(user.reload.valid_password?('newpassword1')).to be true
    end

    it 'unlocks a locked account so the new password works right away', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      user.lock_access!
      token = user.send_reset_password_instructions
      put :update, params: { user: { reset_password_token: token, password: 'newpassword1',
                                     password_confirmation: 'newpassword1' } }
      expect(user.reload.locked_at).to be_nil
      expect(user.failed_attempts).to eq 0
      expect(user.valid_password?('newpassword1')).to be true
    end
  end
end
