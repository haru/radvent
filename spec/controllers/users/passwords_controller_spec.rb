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
  end
end
