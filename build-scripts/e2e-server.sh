#!/bin/sh

# Starts the server used by the Playwright E2E tests (called from playwright.config.js).
# Rebuilds assets, resets the dedicated E2E database and serves on port 4500.
# env.sh is not sourced because it sets RAILS_ENV=test.

set -eu

cd "$(dirname "$0")/.."

export RAILS_ENV=e2e
export DATABASE_URL=sqlite3:db/radvent_e2e.sqlite3
export SECRET_KEY_BASE_DUMMY=1
# db:migrate loads db/schema.rb into an empty database when the file exists. That file is
# git-ignored and comes from the developer's own database, so point at a file that never
# exists to always build the schema from the migrations.
export SCHEMA=db/e2e_schema_unused.rb

bin/rails assets:precompile
# One rails process per task: after db:drop in the same process, db:migrate and db:seed
# silently do nothing.
bin/rails db:drop
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
exec bin/rails server -p 4500 -b 127.0.0.1
