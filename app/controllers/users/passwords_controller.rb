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
    # depend on whether an account exists. A delivery failure is only logged.
    #
    # @return [void]
    def create
      attributes = normalized_params
      self.resource = resource_class.new(attributes)

      return respond_with(resource) unless email_well_formed?(resource.email)

      deliver_instructions(attributes)
      set_flash_message!(:notice, :send_paranoid_instructions)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    end

    private

    # Normalizes the submitted parameters with the same rules as sign-in (strip whitespace, downcase).
    #
    # @return [Hash] the normalized parameters
    def normalized_params
      Devise::ParameterFilter.new(resource_class.case_insensitive_keys, resource_class.strip_whitespace_keys)
                             .filter(resource_params.permit(:email))
    end

    # Adds a blank or invalid error to the resource unless the address looks like an email address.
    #
    # The decision uses the submitted string only, never the stored accounts.
    #
    # @param email [String, nil] the normalized address
    # @return [Boolean] true when the address may be looked up
    def email_well_formed?(email)
      if email.blank?
        resource.errors.add(:email, :blank)
      elsif !Devise.email_regexp.match?(email)
        resource.errors.add(:email, :invalid)
      end
      resource.errors.empty?
    end

    # Sends the instructions, swallowing failures so the response never depends on the outcome.
    #
    # This is an intentional, documented fallback (ADR-0008): a failure only occurs for registered
    # addresses, so showing it would reveal the account. Only the exception class and message are
    # logged, never the token, the address or the mail body.
    #
    # @param attributes [Hash] the normalized reset parameters
    # @return [void]
    def deliver_instructions(attributes)
      resource_class.send_reset_password_instructions(attributes)
    rescue StandardError => e
      Rails.logger.error("Password reset mail was not delivered: #{e.class}: #{e.message}")
    end
  end
end
