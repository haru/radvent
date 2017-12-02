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
bundle exec rake db:create RAILS_ENV=production
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rails s -e production
