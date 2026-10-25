# 0013. E2E tests run with Playwright against a dedicated Rails environment

## Status

Accepted

## Context

The RSpec suite never drives a real browser, so Stimulus controllers, the
Markdown editor, Turbo and CSRF-protected scripts (likes, comments) are not
exercised end to end (Feature 021). The `test` environment cannot host such
tests: it disables CSRF protection, so a script that forgets the token would
still pass, and it is declared RSpec-only. `development` sends mail over SMTP,
uses a null cache (rate limits do not work) and shares `tmp/pids/server.pid`
with a running dev server. `production` requires SMTP settings and Solid Cache.
`config/database.yml` is git-ignored and generated per developer, so adding an
`e2e:` entry to the example file would not reach existing checkouts.

## Decision

- Add a dedicated Rails environment `e2e` (`config/environments/e2e.rb`):
  production-like (eager load, no reloading, precompiled assets under
  `/e2e-assets`), CSRF protection left on, `:memory_store` cache so rate-limit
  counters start fresh on every boot, and `:test` mail delivery.
- Select the database with `DATABASE_URL=sqlite3:db/radvent_e2e.sqlite3`, set
  unconditionally inside the server script. Without it, Rails raises instead of
  falling back to another environment's database.
- Run everything with one command, `yarn e2e` (`playwright test`). Playwright's
  `webServer` starts `build-scripts/e2e-server.sh`, which precompiles assets,
  resets the database (`db:drop`, `db:create`, `db:migrate`, `db:seed`, each in
  its own `rails` process because chaining them after `db:drop` silently skips
  the migration and seed; `SCHEMA` points at a non-existent file so the schema
  is always built from migrations instead of the developer's git-ignored
  `db/schema.rb`) and then `exec`s
  `rails server -p 4500 -b 127.0.0.1`. `reuseExistingServer` is `false`, so a
  process already on the port stops the run before any scenario.
- Keep the scenarios in one file inside `test.describe.serial`; each story
  inherits the previous story's data and a failure marks later tests as
  "did not run". `retries` is `0` so flaky tests are not hidden.

## Consequences

- Only `db/radvent_e2e.sqlite3` is ever deleted; development and test
  databases, `db/schema.rb` and `public/assets` are untouched.
- Rate limits stay enabled, so the scenarios reuse each user's login state
  instead of logging in repeatedly.
- E2E is not part of CI or `bundle exec rspec`; it is run on demand.

## Alternatives considered

- `RAILS_ENV=test` with a `DATABASE_URL` override: CSRF is off, so rejected.
- `RAILS_ENV=production` with extra variables: leaks E2E concerns into the
  production configuration.
- A `globalSetup` calling rake from Node: the order against server start is
  hard to guarantee.
- A wrapper script that resets and then calls `playwright test`: the port check
  would happen after the reset, wiping the DB under a still-running E2E server.
