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
    include Users::DeviseViews

    # Caps reset requests per client IP address at 5 per hour, whatever the address (FR-010).
    #
    # +prepend: true+ rejects the request before +create+ runs, so a rejected request sends no mail
    # and spends none of the address's slot (FR-012). The answer is the same for every address.
    #
    # @return [void]
    rate_limit to: 5, within: 1.hour, only: :create, prepend: true,
               with: :render_too_many_requests

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

    protected

    # Always unlocks the account when the password is reset.
    #
    # Devise only unlocks via +update+ when an email unlock strategy is enabled, but locks here
    # are lifted by time or by a password reset alone (docs/adr/0012-*): a user who proves
    # control of the mailbox gets back in immediately (FR-006).
    #
    # @param _resource [User] the account being unlocked; unused, always unlockable
    # @return [Boolean] true
    def unlockable?(_resource)
      true
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

    # Looks up the account and sends it the instructions when it exists and its mail slot was claimed.
    #
    # The lookup runs outside the rescue in +send_instructions+, so a database failure still surfaces.
    # A suppressed mail is logged for registered addresses only, without the address, so operators can
    # tell it from a mail that was never requested; the log never reaches the response.
    #
    # @param email [String] the normalized address
    # @return [void]
    def deliver_instructions(email)
      claimed = mail_slot_claimed?(email)
      account = resource_class.find_by(email: email)
      return unless account

      if claimed
        send_instructions(account)
      else
        Rails.logger.info('Password reset mail suppressed: per-address limit')
      end
    end

    # Claims the address's one mail per five minutes (FR-014).
    #
    # The slot is claimed per request, for unregistered addresses as well, so the answer and the cache
    # traffic never depend on whether an account exists (FR-015). It stays claimed even if delivery
    # later fails. The window is fixed from the first claim. The key holds a digest, never the address.
    # +increment+ returns nil when the store fails; that counts as a claim (FR-019, docs/adr/0011-*),
    # and production logs the failure through +Radvent::CacheErrorHandler+.
    #
    # @param email [String] the normalized address
    # @return [Boolean] true when this is the first request for the address in the current five-minute
    #   window, or when the counter store failed
    def mail_slot_claimed?(email)
      key = "password-reset-mail:#{Digest::SHA256.hexdigest(email)}"
      count = Rails.cache.increment(key, 1, expires_in: 5.minutes)
      count.nil? || count == 1
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
