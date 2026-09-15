---
title: Configuration
type: component
sources: [S007]
updated: 2026-08-14
---

# Configuration

Config comes from environment variables, Rails initializers, and
environment-specific settings files (S007). For the app-level env vars
(`DB`, `RADVENT_TITLE`, etc.) and the config-generation rake task, see
[Docker Deployment](./docker-deployment.md) and
[Development Setup](./development-setup.md).

## Rails-standard environment variables

| Variable | Purpose |
|----------|---------|
| `RAILS_SERVE_STATIC_FILES` | Serve `/public` directly in production (S007) |
| `RAILS_LOG_TO_STDOUT` | Redirect logs to STDOUT for container logging (S007) |
| `CI` | Enables eager loading in the test environment when present (S007) |
| `RAILS_MASTER_KEY` | Decrypts credentials when `master.key` is unavailable (S007) |
| `SECRET_KEY_BASE` | Encrypts cookies/sessions in production (S007) |

## Database

Multiple backends (SQLite3/MySQL/PostgreSQL) via standard ActiveRecord
config (`config/database.yml.example`). In production, schema dumping is
disabled to prevent accidental modification of the schema file during
migrations (S007).

## Initializers of note

- `config/initializers/time_formats.rb` — app timezone is **Tokyo**; custom
  date/time formats for UI consistency (S007).
- `config/initializers/constants.rb` — advent calendar constants:
  `Constants::YEAR = 2015`, `MONTH = 12`, `START_DAY = 1`, `END_DAY = 25`
  (S007). These read like stale defaults from the original project rather
  than values meant to be used as-is — worth confirming where/whether the
  app still reads them at runtime.
- `config/initializers/devise.rb` — case-insensitive email lookup; password
  stretches: 1 in test, 12 elsewhere; HTTP Auth configured not to store a
  session (S007).
- Asset precompile adds `application_pack.css`; the **CSS compressor is
  disabled** because SassC crashes on MDB's custom CSS properties (S007) —
  see [Views and Frontend](./views-and-frontend.md) for the MDB/theming
  setup this affects.
- Parameter filtering redacts `:passw`, `:email`, `:secret`, `:token` from
  logs (S007).
- `config/initializers/content_security_policy.rb` — CSP config (S007).
- `.rufo` — Ruby formatter config; `config/puma.rb` — app server config
  (S007).

## Environment-specific behavior

| Env | Behavior |
|-----|----------|
| Development | Code reloading on; cache store is `:null_store` unless `tmp/caching-dev.txt` is present; allowed hosts include the Docker service hostname `app` and GitHub Codespaces domains (S007) |
| Production | Eager loading on; log level `:info` tagged with `:request_id`; static file serving gated by `RAILS_SERVE_STATIC_FILES` (S007) |
| Test | Cache `:null_store`; mailer uses `:test` delivery (emails accumulate in an array, not sent); CSRF protection disabled for easier POST/PATCH specs (S007) |

## Secrets

Credentials are encrypted/decrypted via `RAILS_MASTER_KEY` or a local
`master.key` file; `config/secrets.yml.example` is the template for required
secrets (S007).
