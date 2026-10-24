# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../lib/radvent/mail_settings'

RSpec.describe Radvent::MailSettings do
  describe '.default_url_options' do
    it 'splits an https URL without a port' do
      expect(described_class.default_url_options('RADVENT_URL' => 'https://advent.example.com'))
        .to eq(host: 'advent.example.com', protocol: 'https')
    end

    it 'keeps a non-default port' do
      expect(described_class.default_url_options('RADVENT_URL' => 'http://localhost:3000'))
        .to eq(host: 'localhost', protocol: 'http', port: 3000)
    end

    it 'returns nil when unset or empty' do
      expect([{}, { 'RADVENT_URL' => '' }].map { |env| described_class.default_url_options(env) }).to eq [nil, nil]
    end

    ['advent.example.com', 'http://', 'http://exa mple.com', '://x'].each do |value|
      it "raises a configuration error for #{value.inspect}" do
        expect { described_class.default_url_options('RADVENT_URL' => value) }
          .to raise_error(Radvent::MailSettings::ConfigurationError, /RADVENT_URL/)
      end
    end
  end

  describe '.smtp_settings' do
    let(:full_env) do
      { 'SMTP_ADDRESS' => 'smtp.example.com', 'SMTP_PORT' => '2525', 'SMTP_USERNAME' => 'user',
        'SMTP_PASSWORD' => 'secret', 'SMTP_AUTHENTICATION' => 'plain', 'SMTP_DOMAIN' => 'example.com',
        'SMTP_ENABLE_STARTTLS_AUTO' => 'false' }
    end

    it 'returns nil when SMTP_ADDRESS is unset or empty' do
      expect([{}, { 'SMTP_ADDRESS' => '' }].map { |env| described_class.smtp_settings(env) }).to eq [nil, nil]
    end

    it 'returns the address and defaults only' do
      expect(described_class.smtp_settings('SMTP_ADDRESS' => 'smtp.example.com'))
        .to eq(address: 'smtp.example.com', port: 587, enable_starttls_auto: true)
    end

    it 'returns every configured item' do
      expect(described_class.smtp_settings(full_env))
        .to eq(address: 'smtp.example.com', port: 2525, user_name: 'user', password: 'secret',
               authentication: :plain, domain: 'example.com', enable_starttls_auto: false)
    end

    it 'keeps STARTTLS enabled for any value other than false' do
      expect(described_class.smtp_settings('SMTP_ADDRESS' => 'h', 'SMTP_ENABLE_STARTTLS_AUTO' => 'true'))
        .to include(enable_starttls_auto: true)
    end
  end

  describe '.mailer_sender' do
    it 'returns RADVENT_MAIL_FROM when set' do
      expect(described_class.mailer_sender('RADVENT_MAIL_FROM' => 'noreply@example.com')).to eq 'noreply@example.com'
    end

    it 'falls back to the previous default when unset or empty' do
      expect([{}, { 'RADVENT_MAIL_FROM' => '' }].map { |env| described_class.mailer_sender(env) })
        .to all(eq('please-change-me-at-config-initializers-devise@example.com'))
    end
  end
end
