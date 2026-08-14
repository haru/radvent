---
title: Docker Deployment
type: howto
sources: [S001]
updated: 2026-08-14
---

# Docker Deployment

## Plain docker run (S001)

```bash
docker run -d -p 3000:3000 -v /host/data/directory:/var/radvent_data haru/radvent
```

## docker-compose (MySQL) (S001)

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

docker-compose (PostgreSQL) follows the same shape with `DB: postgres` and a
`postgres` service in place of `mysql` (S001).

## Environment variables (S001)

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

## Manual production deployment (non-Docker) (S001)

```bash
bundle exec rake radvent:generate_default_settings
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rake db:migrate RAILS_ENV=production
export SECRET_KEY_BASE=$(bundle exec rails secret)
bundle exec rails s -e production
```

Contrast with local dev setup in [Development Setup](./development-setup.md).
