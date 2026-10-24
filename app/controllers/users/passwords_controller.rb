# frozen_string_literal: true

# Controllers for the user-facing Devise flows.
module Users
  # Handles password reset requests without revealing whether an account exists.
  #
  # Devise answers an unknown address with a "not found" error and lets a delivery failure surface as
  # an error page for registered addresses only, so either difference tells an outsider which
  # addresses are registered. +create+ therefore answers every well-formed address the same way. See
  # docs/adr/0008-password-reset-hides-account-existence-and-delivery-failure.md.
  class PasswordsController < Devise::PasswordsController
    # Keeps rendering the +devise/passwords+ views, as before this controller existed.
    #
    # The stale scaffold under +app/views/users/passwords+ would otherwise be picked up by the
    # controller's own path and shadow them; it calls a helper Devise no longer provides.
    #
    # @return [Array<String>] no controller-specific view prefix
    def self.local_prefixes
      []
    end

    # Sends the reset instructions to a registered address and always answers with the same notice.
    #
    # A blank or malformed address is rejected with 422 before any lookup, so that answer does not
    # depend on whether an account exists. A delivery failure is only logged and reported.
    #
    # @return [void]
    def create
      self.resource = resource_class.new(normalized_params)

      validate_email_format
      return respond_with(resource) if resource.errors.any?

      deliver_instructions(resource.email)
      respond_with_notice
    end

    private

    # Answers with the generic notice, the same for every well-formed address.
    #
    # @return [void]
    def respond_with_notice
      set_flash_message!(:notice, :send_paranoid_instructions)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    end

    # Normalizes the submitted parameters with the same rules as sign-in (strip whitespace, downcase).
    #
    # @return [Hash] the normalized parameters
    def normalized_params
      Devise::ParameterFilter.new(resource_class.case_insensitive_keys, resource_class.strip_whitespace_keys)
                             .filter(resource_params.permit(:email))
    end

    # Adds a blank or invalid error to the resource unless its address looks like an email address.
    #
    # The decision uses the submitted string only, never the stored accounts.
    #
    # @return [void]
    def validate_email_format
      email = resource.email
      if email.blank?
        resource.errors.add(:email, :blank)
      elsif !Devise.email_regexp.match?(email)
        resource.errors.add(:email, :invalid)
      end
    end

    # Looks up the account and sends it the instructions when it exists.
    #
    # The lookup runs outside the rescue in +send_instructions+, so a database failure still surfaces.
    #
    # @param email [String] the normalized address
    # @return [void]
    def deliver_instructions(email)
      account = resource_class.find_by(email: email)
      send_instructions(account) if account
    end

    # Sends the instructions, swallowing failures so the response never depends on the outcome.
    #
    # This is an intentional, documented fallback (ADR-0008): a failure only occurs for registered
    # addresses, so showing it would reveal the account. Only the exception class is logged, because
    # SMTP errors often quote the recipient; the error is also reported to +Rails.error+ so a tracker
    # can pick it up.
    #
    # @param account [User] the registered user
    # @return [void]
    def send_instructions(account)
      account.send_reset_password_instructions
    rescue StandardError => e
      Rails.logger.error("Password reset mail was not delivered: #{e.class}")
      Rails.error.report(e, handled: true, context: { controller: 'users/passwords#create' })
    end
  end
end
