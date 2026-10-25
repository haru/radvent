#!/bin/sh
set -e
trap 'rc=$?; [ "$rc" -eq 0 ] || echo "startup failed (exit $rc)" >&2' EXIT

echo "RAILS_ENV=${RAILS_ENV:?RAILS_ENV is not set} DB_CREATE_ON_START=${DB_CREATE_ON_START:-false}"

KEYBASE_FILE=/usr/local/keybase

if [ "$SECRET_KEY_BASE" = "" ]
then
  # Do not dump env or use sh -x: it prints secrets to the container logs.
  if [ ! -s "$KEYBASE_FILE" ]
  then
    echo "Generating secret key file"
    bundle exec rails secret > "$KEYBASE_FILE.tmp"
    mv "$KEYBASE_FILE.tmp" "$KEYBASE_FILE"
  fi
  SECRET_KEY_BASE=$(cat "$KEYBASE_FILE")
  export SECRET_KEY_BASE
fi

mkdir -p /var/radvent_data/uploads
mkdir -p /var/radvent_data/protected_uploads
if [ ! -w /var/radvent_data/protected_uploads ]
then
  echo "/var/radvent_data/protected_uploads is not writable" >&2
  exit 1
fi

rm -f /usr/local/radvent/tmp/pids/server.pid
if [ "$DB_CREATE_ON_START" = "true" ]
then
  echo "Creating database"
  bundle exec rake db:create
fi
echo "Migrating database"
bundle exec rake db:migrate
echo "Seeding database"
bundle exec rake db:seed
echo "Starting puma"
exec bundle exec puma -w 3 -p 3000 -e "$RAILS_ENV"
