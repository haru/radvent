#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..

#install Node
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install -y nodejs
npm install -g yarn

# install gems
bundle install

cp travis/database.yml config/

# generate default settings
bundle exec rake radvent:generate_default_settings

# run redmine database migrations
rm -f db/radvent.sqlite3
bundle exec rake db:create
bundle exec rake db:migrate





