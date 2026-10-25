# frozen_string_literal: true

# Represents a user in the system.
#
# Users can create events, publish articles, like items, and comment.
# Uses Devise for authentication.
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable,
         :timeoutable, :recoverable, :lockable
  validates :name, presence: true

  enum :theme, %w[system light dark].index_by(&:itself)

  # Checks if the user is an administrator.
  #
  # @return [Boolean] true if the user has admin privileges
  def admin?
    admin == true
  end

  # Hides the lock from the sign-in failure message.
  #
  # Devise's lockable would answer +:locked+ for a locked account and +:last_attempt+ one attempt
  # before it, which would let an attacker tell a lock from a wrong password. Every failed sign-in
  # answers the same generic message instead (FR-008).
  #
  # @return [Symbol] the generic invalid-credentials message key
  def unauthenticated_message
    message = super
    %i[locked last_attempt].include?(message) ? :invalid : message
  end

  # Keeps locked accounts "active" so already signed-in sessions are not dropped.
  #
  # Devise's activatable hook signs a user out when +active_for_authentication?+ turns false,
  # which would let an attacker lock an account and kick its rightful user out. Whether a new
  # sign-in is allowed is decided by +valid_for_authentication?+, so the lock does not belong
  # here. The same check guards a remember-me cookie, so a locked user whose session timed out
  # is refused like any other new sign-in. This assumes the lock is the only reason Devise
  # reports an account inactive; revisit it when adding a module such as +:confirmable+.
  #
  # @return [Boolean] true whether or not the account is locked
  def active_for_authentication?
    super || access_locked?
  end

  # Locks the account and records the event in the operations log.
  #
  # The log names the account by internal ID only; the address never appears (FR-018).
  #
  # @param opts [Hash] passed through to Devise's +lock_access!+
  # @return [Boolean] whether the lock was saved
  def lock_access!(opts = {})
    saved = super
    Rails.logger.warn("Account locked: user_id=#{id}") if saved
    saved
  end
end
