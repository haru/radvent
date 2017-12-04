#!/bin/sh
set -e

KEYBASE_FILE=/usr/local/keybase

if [ "$SECRET_KEY_BASE" = "" ]
then
  if [ ! -f $KEYBASE_FILE ]
  then
    rake secret > $KEYBASE_FILE
  fi
  export SECRET_KEY_BASE=`cat $KEYBASE_FILE`
fi

mkdir -p /var/radvent_data/uploads

rm -f /usr/local/radvent/tmp/pids/server.pid
if [ "$DB_CREATE_ON_START" = "true" ]
then
  bundle exec rake db:create
fi
bundle exec rake db:migrate
bundle exec rails s
