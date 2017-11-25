#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..

# install gems
bundle install

# run redmine database migrations
rm -f db/test.sqlite3
bundle exec rake db:migrate



