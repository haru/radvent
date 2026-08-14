---
title: Development Setup
type: howto
sources: [S001, S006, S007]
updated: 2026-08-14
---

# Development Setup

## Prerequisites (S001)

- Ruby >= 3.3
- Node.js / Yarn
- SQLite3 (default dev DB)

## Setup steps (S001)

```bash
# 1. Install dependencies
bundle install
yarn install

# 2. Generate default config files
#    Creates config/database.yml / config/secrets.yml / config/initializers/devise.rb
bundle exec rake radvent:generate_default_settings

# 3. Create database, run migrations, and seed data
bundle exec rake db:create db:migrate db:seed
```

See [Configuration](./configuration.md) for what the generated files and
their environment variables control.

## Default admin user (S001)

Seeding (`db:seed`) creates an admin account with a well-known password —
**must be changed after first login**:

| Field | Value |
|-------|-------|
| Email | admin@example.com |
| Password | adminadmin |

## Running the app (S001)

```bash
bundle exec rails s
```

Serves at `http://localhost:3000`. Locale (Japanese/English) switches
automatically based on the browser's language settings.

## Testing (S001)

Framework: RSpec.

```bash
bundle exec rspec spec                        # all tests
bundle exec rspec spec/models                 # model specs only
bundle exec rspec spec/controllers             # controller specs only
bundle exec rspec spec/models/user_spec.rb     # single file
bundle exec rspec spec/models/user_spec.rb:42  # specific line
```

Coverage report (SimpleCov / LCOV) generated at `coverage/index.html` after a
test run. Project policy requires **≥90% coverage** (S006).

| Directory | Contents |
|-----------|----------|
| `spec/models/` | Model specs |
| `spec/controllers/` | Controller specs |
| `spec/helpers/` | Helper specs |
| `spec/uploaders/` | Uploader specs |
| `spec/views/` | View specs |
| `spec/factories/` | FactoryBot factory definitions |

`spec/rails_helper.rb` wires up SimpleCov, FactoryBot's shorthand syntax
(`create(:user)` without the `FactoryBot.` prefix), Devise test helpers
(`sign_in`/`sign_out` in controller specs), and transactional fixtures — each
test runs inside a SQL transaction, so no explicit teardown is needed (S006).
`config/application.rb` sets RSpec as the default test framework generator
and enables controller specs while disabling view/helper/routing spec
generation (S006).

Model specs cover associations, validations, and business logic such as the
`published?` method that gates calendar-item visibility (S006) — see
[Domain Model](./domain-model.md). Controller specs exercise the
`admin_user!` filter and board-visibility access control (S006) — see
[Controllers and Routing](./controllers-and-routing.md). Because visibility
is date-driven, specs make heavy use of `Time.zone` mocking to verify
publish-date transitions (S006).

For containerized deployment instead of local setup, see
[Docker Deployment](./docker-deployment.md). Stack details in
[Tech Stack](./tech-stack.md).
