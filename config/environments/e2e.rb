# The e2e environment is used exclusively by the Playwright E2E tests
# (`yarn e2e`, see docs/e2e-testing.md). It is production-like, but never sends
# mail and keeps CSRF protection on. The throwaway database is selected by
# DATABASE_URL in build-scripts/e2e-server.sh.

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot so loading mistakes surface at startup.
  config.eager_load = true

  # Show full error reports so a failing scenario can be traced from the page and the log.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = true

  # Serve the precompiled assets from /public.
  config.public_file_server.enabled = true

  # Use only precompiled assets. The separate prefix keeps public/assets (development) untouched.
  config.assets.compile = false
  config.assets.prefix = "/e2e-assets"

  # Rate-limit counters live in the server process, so every boot starts from zero.
  config.cache_store = :memory_store

  # Keep uploaded images out of the development directory (storage/protected_uploads), where the
  # E2E database's ids would collide with real records.
  config.x.protected_upload_root = Rails.root.join('tmp/e2e/protected_uploads')

  # Never deliver mail to the real world.
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :test

  # Do not rewrite db/schema.rb (used by development) after migrating.
  config.active_record.dump_schema_after_migration = false

  # Log deprecation notices.
  config.active_support.report_deprecations = true

  # CSRF protection stays at its default (enabled) so the scripts' tokens are verified.
end
