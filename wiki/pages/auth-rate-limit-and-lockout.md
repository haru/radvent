---
title: Authentication Rate Limits and Account Lockout
type: decision
sources: [S035, S036, S037, S038, S040]
updated: 2026-10-30
---

# Authentication Rate Limits and Account Lockout

Feature `020-auth-rate-limit-lockout` (Issue #289) limits brute-force sign-in, bot sign-ups and reset-mail flooding (S035).

## Limits

| Endpoint | Limit | Over the limit |
|----------|-------|----------------|
| `Users::SessionsController#create` | 10 / minute / IP | 429 page (S035) |
| `Users::RegistrationsController#create` | 5 / hour / IP, failed submissions count | 429 page (S035) |
| `Users::PasswordsController#create` | 5 / hour / IP | 429 page (S035) |
| Reset mail per address | 1 per 5 minutes, key `password-reset-mail:<SHA-256>` | same notice as always, no mail (S035) |

- Declared with Rails `rate_limit ..., only: :create, prepend: true`; `prepend: true` is mandatory so a rejected request never reaches Devise's password check or adds a failed attempt (S035).
- `ApplicationController#render_too_many_requests` renders `errors/too_many_requests` with 429 and logs `Rate limit exceeded: <controller>#<action>`, never the address or password (S035).
- The three controllers share `Users::DeviseViews` (empty `local_prefixes`) so the existing `devise/*` views keep rendering (S035).

## Shared counters

- Production uses `solid_cache` in the primary database (`solid_cache_entries`), because the default file store under `tmp/cache` is not shared between hosts or containers and is lost when a container is recreated. Redis, Rack::Attack and a separate cache DB were rejected (S036).
- Transient store failures make `increment` return `nil`: requests proceed unlimited, the error goes to `Rails.error` and, through `Radvent::CacheErrorHandler` (Solid Cache's default handler logs nothing because `SolidCache::Store.logger` is unset), to the log as `SolidCacheStore: increment failed, returned nil: <exception class>`. This is a deliberate, documented fallback; permanent faults still 500 (S036).
- Behind a proxy or CDN, add it to `config.action_dispatch.trusted_proxies`, or everyone counts as one IP (S036).
- Development uses `:null_store` unless `tmp/caching-dev.txt` exists, so no limit applies there by default (S036).
- Test env uses `:memory_store`, cleared before each example, because `:null_store` never counts (S035).
- The `e2e` env also uses `:memory_store` (fresh per boot) and keeps the limits on; see [E2E Scenario Design](./e2e-scenario-design.md) (S038).

## Reuse outside authentication

The board member search reuses `rate_limit` with the Solid Cache counters, keyed by user id instead of IP, and answers 429 through `render_too_many_requests` — see [Board Member Search](board-member-search.md) (S040).

## Account lockout

- Devise `:lockable`: 10 consecutive failures lock for 15 minutes, time-based unlock only; the `failed_attempts` and `locked_at` columns already exist from the initial Devise migration, `unlock_token` stays unused, no unlock mail, unlock routes skipped (S037).
- A locked account gets the same failure message and redirect as a wrong password or unknown address (`unauthenticated_message` maps `:locked` to `:invalid`) (S037).
- `active_for_authentication?` stays true while locked, so existing sessions are not cut (S037).
- A password reset unlocks the account (`unlockable?` returns true); a lock logs `Account locked: user_id=<id>` (S037).

Builds on [Password Reset Hides Account Existence](password-reset-account-hiding.md); see also [Configuration](configuration.md).
