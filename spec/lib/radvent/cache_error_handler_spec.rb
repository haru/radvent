# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../lib/radvent/cache_error_handler'

RSpec.describe Radvent::CacheErrorHandler do
  let(:error) { ActiveRecord::ConnectionNotEstablished.new('connection to db.internal refused') }

  before { allow(Rails.logger).to receive(:error) }

  describe '.call' do
    it 'logs the failed operation and the exception class at error level' do
      described_class.call(method: :increment, returning: nil, exception: error)
      expect(Rails.logger).to have_received(:error)
        .with('SolidCacheStore: increment failed, returned nil: ActiveRecord::ConnectionNotEstablished')
    end

    it 'leaves the exception message out of the log' do
      described_class.call(method: :increment, returning: nil, exception: error)
      expect(Rails.logger).not_to have_received(:error).with(a_string_including('db.internal'))
    end
  end

  describe 'wired into a real Solid Cache store' do
    let(:store) { SolidCache::Store.new(error_handler: described_class.method(:call)) }

    before do
      allow(SolidCache::Entry).to receive(:lock_and_write).and_raise(error)
      allow(Rails.error).to receive(:report)
    end

    it 'logs a transient counter failure instead of dropping it silently', :aggregate_failures do
      expect(store.increment('rate-limit:key', 1, expires_in: 1.minute)).to be_nil
      expect(Rails.logger).to have_received(:error).with(a_string_including('SolidCacheStore: increment failed'))
    end
  end
end
