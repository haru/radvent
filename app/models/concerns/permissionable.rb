# frozen_string_literal: true

# Concern providing a unified permission interface for all content models.
#
# Any model including this concern MUST implement visible?, editable?, and deletable?.
# The default implementations raise NotImplementedError to enforce the contract.
module Permissionable
  extend ActiveSupport::Concern

  # Returns true if the given user can view this object.
  #
  # @param user [User, nil] nil means unauthenticated
  # @return [Boolean]
  def visible?(user)
    raise NotImplementedError, "#{self.class}#visible? not implemented"
  end

  # Returns true if the given user can edit/modify this object.
  #
  # @param user [User, nil]
  # @return [Boolean]
  def editable?(user)
    raise NotImplementedError, "#{self.class}#editable? not implemented"
  end

  # Returns true if the given user can delete this object.
  #
  # @param user [User, nil]
  # @return [Boolean]
  def deletable?(user)
    raise NotImplementedError, "#{self.class}#deletable? not implemented"
  end
end
