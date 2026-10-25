---
title: E2E Tests with Playwright (Dedicated Rails Environment)
type: decision
sources: [S038, S039]
updated: 2026-10-25
---

# E2E Tests with Playwright (Dedicated Rails Environment)

Feature `021-e2e-playwright-tests` adds browser-driven tests of the main user journey, run with `yarn e2e` (S038, S039). Scenario structure is on [E2E Scenario Design](./e2e-scenario-design.md).

## Why a dedicated environment

- RSpec never drives a real browser, so Stimulus controllers, the Markdown editor, Turbo and CSRF-protected scripts (likes, comments) were not exercised end to end (S039).
- `test` disables CSRF protection (a script that forgets the token would still pass) and is RSpec-only. `development` sends mail over SMTP, uses a null cache by default (rate limits do not work) and shares `tmp/pids/server.pid` with a running dev server. `production` expects SMTP settings and Solid Cache (S039).

## The `e2e` environment (`config/environments/e2e.rb`)

- Production-like: eager load, no reloading, `consider_all_requests_local`, precompiled assets only, served under the prefix `/e2e-assets` (`public/e2e-assets`) so `public/assets` stays untouched (S038).
- `:memory_store` cache, so rate-limit counters start from zero on every boot (S038); see [rate limits](./auth-rate-limit-and-lockout.md).
- Mail uses `:test` delivery; CSRF protection stays on; `dump_schema_after_migration = false` keeps `db/schema.rb` untouched (S038).
- Uploaded images go to `tmp/e2e/protected_uploads` instead of `storage/protected_uploads`, whose ids would collide with real records (S038); compare [Protected Image Serving](./protected-image-serving.md).

## Database

- `DATABASE_URL=sqlite3:db/radvent_e2e.sqlite3` is set unconditionally inside the server script. `config/database.yml` is git-ignored and generated per developer, so an `e2e:` entry in the example file would not reach existing checkouts. Without the URL, Rails raises instead of falling back to another environment's database (S038, S039).
- Reset order: `db:drop`, `db:create`, `db:migrate`, `db:seed`, each in its own `rails` process, because chaining them after `db:drop` silently skips the migration and seed. `SCHEMA` points at a non-existent file so the schema is always built from migrations, not from the developer's git-ignored `db/schema.rb` (S038, S039).

## Runner

- `yarn e2e` runs `playwright test`; the `webServer` starts `build-scripts/e2e-server.sh`, which precompiles assets, resets the database and `exec`s `rails server -p 4500 -b 127.0.0.1 --log-to-stdout`, so Playwright stops Puma itself (S038, S039).
- `reuseExistingServer: false`: a process already on port 4500 stops the run before any scenario. Startup timeout is 300 s, covering the asset build and several Rails boots (S038).
- `workers: 1`, `retries: 0`, `forbidOnly: true`, so flaky tests are not hidden (S038, S039).
- Local Chromium via `yarn playwright install chromium`. The devcontainer installs the OS libraries in `.devcontainer/Dockerfile` and Chromium in `post-create.sh`. The `browserless` service is not used, since it would need the app on `0.0.0.0` and a CDP connection (S038).
- Not part of CI or `bundle exec rspec`; run on demand (S039).

## Alternatives rejected (S039)

- `RAILS_ENV=test` with a `DATABASE_URL` override: CSRF is off.
- `RAILS_ENV=production` plus variables: leaks E2E concerns into production config.
- A `globalSetup` calling rake, or a wrapper script that resets before `playwright test`: ordering against the port check cannot be guaranteed, and the reset could wipe a database under a still-running E2E server.

See also [Development Setup](./development-setup.md).
