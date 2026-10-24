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

    # The SMTP authentication methods accepted for +SMTP_AUTHENTICATION+.
    SMTP_AUTHENTICATIONS = %w[plain login cram_md5 xoauth2].freeze

    # The variables password reset mails need; without them the mail cannot be delivered properly.
    REQUIRED_VARIABLES = %w[RADVENT_URL SMTP_ADDRESS RADVENT_MAIL_FROM].freeze

    module_function

    # Builds +action_mailer.default_url_options+ from +RADVENT_URL+.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Hash, nil] host, protocol and (when not the default) port, or nil when unset
    # @raise [ConfigurationError] when the value is not an absolute http(s) URL with a host
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
    # STARTTLS stays enabled unless +SMTP_ENABLE_STARTTLS_AUTO+ is +false+ (case-insensitive).
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Hash, nil] the settings, or nil when +SMTP_ADDRESS+ is unset
    # @raise [ConfigurationError] when +SMTP_PORT+ is not an integer or +SMTP_AUTHENTICATION+ is unknown
    def smtp_settings(env)
      address = present(env, 'SMTP_ADDRESS')
      return unless address

      { address: address,
        port: smtp_port(env),
        enable_starttls_auto: present(env, 'SMTP_ENABLE_STARTTLS_AUTO')&.downcase != 'false',
        user_name: present(env, 'SMTP_USERNAME'),
        password: present(env, 'SMTP_PASSWORD'),
        domain: present(env, 'SMTP_DOMAIN'),
        authentication: smtp_authentication(env) }.compact
    end

    # Lists the variables password reset mails need that are unset or empty.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Array<String>] the missing variable names
    def missing_variables(env)
      REQUIRED_VARIABLES.reject { |name| present(env, name) }
    end

    # Returns the sender address of the Devise mails.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [String] +RADVENT_MAIL_FROM+, or +DEFAULT_MAILER_SENDER+ when unset
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

    # Reads +SMTP_PORT+.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Integer] the port
    # @raise [ConfigurationError] when it is not an integer
    def smtp_port(env)
      Integer(present(env, 'SMTP_PORT') || DEFAULT_SMTP_PORT)
    rescue ArgumentError
      raise ConfigurationError, "SMTP_PORT must be an integer: #{env['SMTP_PORT'].inspect}"
    end

    # Reads +SMTP_AUTHENTICATION+.
    #
    # @param env [Hash{String => String}] the environment variables
    # @return [Symbol, nil] the method, or nil when unset
    # @raise [ConfigurationError] when it is not one of +SMTP_AUTHENTICATIONS+
    def smtp_authentication(env)
      value = present(env, 'SMTP_AUTHENTICATION')
      return unless value
      return value.to_sym if SMTP_AUTHENTICATIONS.include?(value)

      raise ConfigurationError,
            "SMTP_AUTHENTICATION must be one of #{SMTP_AUTHENTICATIONS.join(', ')}: #{value.inspect}"
    end

    # Parses +RADVENT_URL+ and checks it is an http(s) URL with a host.
    #
    # @param value [String] the raw value
    # @return [URI::Generic] the parsed URL
    # @raise [ConfigurationError] when it cannot be used
    def parse_url(value)
      uri = URI.parse(value)
      return uri if %w[http https].include?(uri.scheme) && !uri.host.to_s.empty?

      raise ConfigurationError, url_error(value)
    rescue URI::InvalidURIError
      raise ConfigurationError, url_error(value)
    end

    # Builds the message for an unusable +RADVENT_URL+.
    #
    # @param value [String] the raw value
    # @return [String] the message
    def url_error(value)
      "RADVENT_URL must be an absolute http(s) URL like https://advent.example.com: #{value.inspect}"
    end

    private_class_method :present, :smtp_port, :smtp_authentication, :parse_url, :url_error
  end
end
