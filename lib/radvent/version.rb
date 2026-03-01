# frozen_string_literal: true

# Main module for the Radvent application.
module Radvent
  # Module for version information.
  module Version
    # The current version of Radvent.
    VERSION = '3.0.0'

    # Returns the current version string.
    #
    # @return [String] the version
    def self.version
      VERSION
    end
  end
end
