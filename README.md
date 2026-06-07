# radvent

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![build](https://github.com/haru/radvent/actions/workflows/build.yml/badge.svg)](https://github.com/haru/radvent/actions/workflows/build.yml)
[![Maintainability](https://qlty.sh/gh/haru/projects/radvent/maintainability.svg)](https://qlty.sh/gh/haru/projects/radvent)
[![codecov](https://codecov.io/gh/haru/radvent/branch/main/graph/badge.svg?token=MM74F6ZLL6)](https://codecov.io/gh/haru/radvent)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/haru/radvent)

**[Japansese/日本語](README.ja.md)**

An Advent Calendar-style blog web application. Write articles in Markdown and they are automatically published on their scheduled date.

This is a fork of [nanonanomachine/radvent](https://github.com/nanonanomachine/radvent) with the following additions and enhancements:

- User authentication (Devise)
- Per-user event management (multiple boards with public / protected / private visibility and membership control)
- Multiple Advent Calendar events
- Likes and comments
- File attachments (CarrierWave)

The Markdown editor uses [EasyMDE](https://github.com/Ionaru/easy-markdown-editor), the Markdown parser uses [marked](https://github.com/markedjs/marked), and syntax highlighting uses [highlight.js](https://github.com/highlightjs/highlight.js).

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Development Setup](#development-setup)
- [Starting the App](#starting-the-app)
- [Testing](#testing)
- [Production Deployment](#production-deployment)
- [Docker](#docker)
- [Architecture](#architecture)
- [Environment Variables](#environment-variables)
- [License](#license)

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Language | Ruby >= 3.2 |
| Framework | Ruby on Rails 8.1 |
| Frontend | esbuild / PostCSS (Bootstrap 5 / mdb-ui-kit) / @hotwired/stimulus |
| Markdown Editor | EasyMDE (easy-markdown-editor) |
| Templates | HAML |
| Authentication | Devise |
| DB (development) | SQLite3 |
| DB (production) | SQLite3 / MySQL 5.7+ / PostgreSQL |
| Testing | RSpec / FactoryBot / SimpleCov |
| CI | GitHub Actions |

---

## Development Setup

### Prerequisites

- Ruby >= 3.2
- Node.js / Yarn
- SQLite3 (default)

### Steps

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

### Default Admin User

After seeding (`db:seed`), the following admin account is available. **Please change the password after your first login.**

| Field | Value |
|-------|-------|
| Email | admin@example.com |
| Password | adminadmin |

---

## Starting the App

```bash
bundle exec rails s
```

Access the app at `http://localhost:3000`.

The app supports Japanese and English locales, and automatically switches based on your browser's language settings.

---

## Testing

The test framework used is **RSpec**.

### Run All Tests

```bash
bundle exec rspec spec
```

### Run Specific Tests

```bash
# Model specs only
bundle exec rspec spec/models

# Controller specs only
bundle exec rspec spec/controllers

# Single file
bundle exec rspec spec/models/user_spec.rb

# Specific line in a file
bundle exec rspec spec/models/user_spec.rb:42
```

### Coverage Report

After running tests, a coverage report is generated at `coverage/index.html` (SimpleCov / LCOV format).

```bash
bundle exec rspec spec
open coverage/index.html
```

### Test Structure

| Directory | Contents |
|-----------|----------|
| `spec/models/` | Model specs |
| `spec/controllers/` | Controller specs |
| `spec/helpers/` | Helper specs |
| `spec/uploaders/` | Uploader specs |
| `spec/views/` | View specs |
| `spec/factories/` | FactoryBot factory definitions |

---

## Production Deployment

```bash
# 1. Generate config files
bundle exec rake radvent:generate_default_settings

# 2. Precompile assets
bundle exec rake assets:precompile RAILS_ENV=production

# 3. Run database migrations
bundle exec rake db:migrate RAILS_ENV=production

# 4. Set secret key and start
export SECRET_KEY_BASE=$(bundle exec rails secret)
bundle exec rails s -e production
```

---

## Docker

### Running with docker run

```bash
docker run -d -p 3000:3000 -v /host/data/directory:/var/radvent_data haru/radvent
```

### docker-compose Example (MySQL)

```yaml
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    restart: unless-stopped
    volumes:
      - "./docker/data:/var/radvent_data"
      - "./log:/usr/local/radvent/log"
    links:
      - mysql
    environment:
      DB: mysql
      DB_USERNAME: root
      DB_PASSWORD: example
      DB_HOST: mysql
      DB_CREATE_ON_START: "true"
  mysql:
    image: mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: example
    volumes:
      - "./docker/mysql:/var/lib/mysql"
```

### docker-compose Example (PostgreSQL)

```yaml
services:
  radvent:
    image: haru/radvent:latest
    ports:
      - "3000:3000"
    volumes:
      - "./docker/data:/var/radvent_data"
      - "./log:/usr/local/radvent/log"
    restart: unless-stopped
    environment:
      DB: postgres
      DB_USERNAME: postgres
      DB_PASSWORD: example
      DB_HOST: postgres
      DB_CREATE_ON_START: "true"
  postgres:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - "./docker/postgres:/var/lib/postgresql"
```

### Environment Variables

| Key | Value | Default |
|-----|-------|---------|
| `DB` | `sqlite3` / `mysql` / `postgres` | `sqlite3` |
| `DB_NAME` | Database name | `radvent` |
| `DB_USERNAME` | DB username | — |
| `DB_PASSWORD` | DB password | — |
| `DB_HOST` | DB hostname | — |
| `DB_PORT` | DB port number | MySQL: `3306` / PostgreSQL: `5432` |
| `DB_CREATE_ON_START` | Set to `true` to run `db:create` on startup | `false` |
| `RADVENT_TITLE` | Site name displayed in the header | `Advent Calendar` |

---

## Architecture

### Entity Relationship Diagram

```
Board ──< Event ──< AdventCalendarItem >── User
  │                       │
  └──< BoardMembership    └── Item ──< Comment
         >── User                └──< Like >── User
```

| Model | Description |
|-------|-------------|
| `User` | Devise-authenticated user. Has admin flag |
| `Board` | Container for events. Two types: `top` (system-wide) and `user` (user-created), with `public` / `protected` / `private` visibility |
| `BoardMembership` | Join table between `Board` and `User` (membership management) |
| `Event` | Advent Calendar event. Belongs to a `Board` |
| `AdventCalendarItem` | Calendar date slot (`date` is Integer 1–31) |
| `Item` | Markdown article. Has a one-to-one relationship with `AdventCalendarItem` |
| `Like` | Like on an article |
| `Comment` | Comment on an article (stores `user_name` as a string only) |
| `Attachment` | File attachment via CarrierWave |

---

## License

[MIT](LICENSE)

---

## Credits

- Original radvent: [Yohei Koyama](https://github.com/nanonanomachine)
- Maintainer: [haru](https://github.com/haru)
