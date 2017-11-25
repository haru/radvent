#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..

# install gems
bundle install

# generate default settings
bundle exec rake radvent:generate_default_settings

# run redmine database migrations
rm -f db/test.sqlite3
bundle exec rake db:migrate



