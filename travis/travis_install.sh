#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..

if [ "$DB" = "mysql" ]
then
  export DB_USER="root"
  export DB_HOST="localhost"
fi

if [ "$DB" = "postgres" ]
then
  export DB_USER="postgres"
  export DB_HOST="localhost"
fi

# install gems
bundle install

cp travis/database.yml config/

# generate default settings
bundle exec rake radvent:generate_default_settings

# run redmine database migrations
rm -f db/radvent.sqlite3
bundle exec rake db:create
bundle exec rake db:migrate



