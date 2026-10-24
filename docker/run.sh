#!/bin/sh
set -e

KEYBASE_FILE=/usr/local/keybase

if [ "$SECRET_KEY_BASE" = "" ]
then
  if [ ! -f $KEYBASE_FILE ]
  then
    echo "Generating secret key file"
    bundle exec rails secret > $KEYBASE_FILE
  fi
  export SECRET_KEY_BASE=`cat $KEYBASE_FILE`
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
bundle exec puma -w 3 -p 3000 -e $RAILS_ENV
