# frozen_string_literal: true

# Main module for the Radvent application.
module Radvent
  # Records transient Solid Cache failures in the application log.
  #
  # Solid Cache's default handler logs only when +SolidCache::Store.logger+ is set, which Rails never
  # does, so a counter-store failure would silently switch the authentication rate limits off
  # (FR-019). Kept free of Rails so it can be required from +config/environments/production.rb+
  # before the autoloader is ready.
  module CacheErrorHandler
    # Logs the failed cache operation at error level.
    #
    # Only the exception class is logged: database errors often quote the SQL, which holds cache
    # keys derived from client addresses.
    #
    # @param method [Symbol] the cache operation that failed, such as +:increment+
    # @param returning [Object] the value the store returns instead of raising
    # @param exception [Exception] the transient error that was rescued
    # @return [void]
    def self.call(method:, returning:, exception:)
      Rails.logger.error("SolidCacheStore: #{method} failed, returned #{returning.inspect}: #{exception.class}")
    end
  end
end
