---
title: Development Setup
type: howto
sources: [S001]
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
test run.

| Directory | Contents |
|-----------|----------|
| `spec/models/` | Model specs |
| `spec/controllers/` | Controller specs |
| `spec/helpers/` | Helper specs |
| `spec/uploaders/` | Uploader specs |
| `spec/views/` | View specs |
| `spec/factories/` | FactoryBot factory definitions |

For containerized deployment instead of local setup, see
[Docker Deployment](./docker-deployment.md). Stack details in
[Tech Stack](./tech-stack.md).
