# frozen_string_literal: true

# Keeps Devise controllers rendering the shared +devise/*+ views.
#
# Rails looks up templates under the controller's own path first, so the stale
# scaffolds under +app/views/users/+ would shadow the Devise views once a
# controller named +Users::SessionsController+ or +Users::RegistrationsController+
# exists. Clearing the local prefixes makes every Devise controller keep using
# the +devise/*+ views, as +Users::PasswordsController+ did before this concern was extracted.
module Users
  # Renders the +devise/*+ views instead of controller-specific ones.
  module DeviseViews
    extend ActiveSupport::Concern

    # Class methods added to every controller including this concern.
    module ClassMethods
      private

      # @return [Array<String>] no controller-specific view prefix
      def local_prefixes
        []
      end
    end
  end
end
