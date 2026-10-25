# 0011. Share authentication rate-limit counters in Solid Cache

## Status

Accepted

## Context

Sign-in, sign-up and password-reset requests are rate limited per connection
and, for reset mail, per address (Issue #289). Rails' `rate_limit` counts in
`config.cache_store`, which was unset, so Rails fell back to a file store under
`tmp/cache`. Workers on one host share that, but a second host or container
would count on its own, and `tmp/cache` is lost whenever the container is
recreated, which resets every counter.

## Decision

- Add the `solid_cache` gem and set `config.cache_store = :solid_cache_store`
  in production. No separate cache database: the `solid_cache_entries` table
  lives in the primary database (SQLite, MySQL or PostgreSQL), which every
  process already shares.
- Declare `rate_limit ..., only: :create, prepend: true` on the Devise-derived
  `Users::SessionsController`, `Users::RegistrationsController` and
  `Users::PasswordsController`. `prepend: true` is required so a rejected
  request never reaches Devise's password check and adds no failed attempt.
- A transient store failure (connection loss, deadlock, lock timeout) makes
  `increment` return `nil`; the request then proceeds without a limit. Solid
  Cache reports the failure to `Rails.error`, but its default handler logs only
  when `SolidCache::Store.logger` is set, which Rails never does. Production
  therefore passes `Radvent::CacheErrorHandler` as `error_handler:`, which logs
  `SolidCacheStore: increment failed, returned nil: <exception class>` at error
  level (class only, because database errors may quote cache keys). This is an intentional, documented
  fallback: locking everyone out because the counter store hiccuped is worse
  than briefly losing the limit. Permanent faults (missing table and so on)
  are not covered by the failsafe and surface as a 500.
- Account failure counts live in `users`, not in the cache, and are not subject
  to this fallback.

## Consequences

- One counter per connection and operation, shared by all processes and hosts.
- Behind a reverse proxy or CDN, `config.action_dispatch.trusted_proxies` must
  include the proxy, otherwise all clients count as one address.
- Development uses `:null_store` unless `tmp/caching-dev.txt` exists, so no
  limit applies there by default.
- Rejected requests are logged as `Rate limit exceeded: <controller>#<action>`.
- Redis, Rack::Attack, a separate cache database and a hand-written counter
  table were rejected as heavier than this app needs.
