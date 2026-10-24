# frozen_string_literal: true

require 'uri'

# Main module for the Radvent application.
module Radvent
  # Builds the mail configuration from environment variables.
  #
  # Kept free of Rails so it can be required from +config/environments/production.rb+ before the
  # autoloader is ready and be tested without booting a production environment.
  module MailSettings
    # Raised when an environment variable holds a value that cannot be used.
    class ConfigurationError < StandardError; end

    # The Devise sender used when +RADVENT_MAIL_FROM+ is not set.
    DEFAULT_MAILER_SENDER = 'please-change-me-at-config-initializers-devise@example.com'

    # The SMTP port used when +SMTP_PORT+ is not set.
    DEFAULT_SMTP_PORT = 587

    # Optional SMTP settings copied from an environment variable to a +smtp_settings+ key.
    OPTIONAL_SMTP_KEYS = { 'SMTP_USERNAME' => :user_name, 'SMTP_PASSWORD' => :password,
                           'SMTP_DOMAIN' => :domain }.freeze

    module_function

    # Builds +action_mailer.default_url_options+ from +RADVENT_URL+.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Hash, nil] host, protocol and (when not the default) port, or nil when unset
    # @raise [ConfigurationError] when the value is not an absolute URL with a host
    def default_url_options(env)
      value = present(env, 'RADVENT_URL')
      return unless value

      uri = parse_url(value)
      options = { host: uri.host, protocol: uri.scheme }
      options[:port] = uri.port unless uri.port == uri.default_port
      options
    end

    # Builds +action_mailer.smtp_settings+ from the +SMTP_*+ variables.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Hash, nil] the settings, or nil when +SMTP_ADDRESS+ is unset
    def smtp_settings(env)
      address = present(env, 'SMTP_ADDRESS')
      return unless address

      settings = { address: address, port: Integer(present(env, 'SMTP_PORT') || DEFAULT_SMTP_PORT),
                   enable_starttls_auto: present(env, 'SMTP_ENABLE_STARTTLS_AUTO') != 'false' }
      OPTIONAL_SMTP_KEYS.each { |name, key| (value = present(env, name)) && settings[key] = value }
      authentication = present(env, 'SMTP_AUTHENTICATION')
      settings[:authentication] = authentication.to_sym if authentication
      settings
    end

    # Returns the sender address of the Devise mails.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [String] +RADVENT_MAIL_FROM+, or the previous default when unset
    def mailer_sender(env)
      present(env, 'RADVENT_MAIL_FROM') || DEFAULT_MAILER_SENDER
    end

    # Returns the value of an environment variable, treating an empty string as unset.
    #
    # @param env [Hash{String => String}] the environment variables
    # @param name [String] the variable name
    # @return [String, nil] the value or nil
    def present(env, name)
      value = env[name]
      value unless value.to_s.empty?
    end

    # Parses +RADVENT_URL+ and checks it has a scheme and a host.
    #
    # @param value [String] the raw value
    # @return [URI::Generic] the parsed URL
    # @raise [ConfigurationError] when it cannot be used
    def parse_url(value)
      uri = URI.parse(value)
      raise URI::InvalidURIError if uri.host.to_s.empty? || uri.scheme.nil?

      uri
    rescue URI::InvalidURIError
      raise ConfigurationError, "RADVENT_URL must be an absolute URL like https://advent.example.com: #{value.inspect}"
    end
  end
end
