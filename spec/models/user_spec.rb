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

  describe 'account lock' do
    let(:user) { create(:user, email: 'lock@example.com', password: 'hogehoge') }

    # Mirrors the Warden strategy call: the block performs the password check.
    #
    # @param password_valid [Boolean] whether the submitted password is correct
    # @return [Boolean] whether the account may authenticate
    def attempt_sign_in(password_valid)
      user.valid_for_authentication? { password_valid }
    end

    context 'after ten consecutive failed attempts' do # rubocop:disable RSpec/ContextWording
      before { 10.times { attempt_sign_in(false) } }

      it 'locks the account', :aggregate_failures do
        expect(user.reload.access_locked?).to be true
        expect(user.failed_attempts).to eq 10
      end

      it 'rejects the correct password too' do
        expect(attempt_sign_in(true)).to be false
      end

      it 'does not extend the lock time on further attempts' do
        locked_at = user.reload.locked_at
        attempt_sign_in(false)
        expect(user.reload.locked_at).to eq locked_at
      end

      it 'answers the generic invalid message instead of revealing the lock' do
        expect(user.unauthenticated_message).to eq :invalid
      end
    end

    context 'after the lock time of 15 minutes has passed' do # rubocop:disable RSpec/ContextWording
      before do
        10.times { attempt_sign_in(false) }
        # `travel` truncates to whole seconds by default, which would race the
        # sub-second precision of locked_at in Devise's strict comparison.
        travel_to(user.reload.locked_at + 15.minutes + 1.second, with_usec: true)
      end

      it 'lets the correct password through again and resets the counter', :aggregate_failures do
        expect(attempt_sign_in(true)).to be true
        expect(user.reload.failed_attempts).to eq 0
        expect(user.locked_at).to be_nil
      end
    end

    it 'maps the last-attempt warning to the generic message even if Devise were to enable it' do
      allow(described_class).to receive(:last_attempt_warning).and_return(true)
      9.times { attempt_sign_in(false) }
      expect(user.reload.unauthenticated_message).to eq :invalid
    end

    it 'stays active for authentication while locked so signed-in sessions survive' do
      10.times { attempt_sign_in(false) }
      expect(user.reload.active_for_authentication?).to be true
    end

    it 'logs the lock without the address', :aggregate_failures do
      allow(Rails.logger).to receive(:warn)
      user.lock_access!
      expect(Rails.logger).to have_received(:warn).with("Account locked: user_id=#{user.id}")
      expect(Rails.logger).not_to have_received(:warn).with(a_string_including('lock@example.com'))
    end

    it 'does not log a lock that could not be saved', :aggregate_failures do
      allow(Rails.logger).to receive(:warn)
      allow(user).to receive(:save).and_return(false)
      expect(user.lock_access!).to be false
      expect(Rails.logger).not_to have_received(:warn).with(a_string_including('Account locked'))
    end

    it 'returns what Devise returns when the lock is saved' do
      expect(user.lock_access!).to be true
    end

    it 'sends no mail when locking' do
      expect { user.lock_access! }.not_to(change { ActionMailer::Base.deliveries.size })
    end
  end
end
