#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..

#install Node
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs
npm install -g yarn

# install npm dependencies
yarn install

# install gems
gem install bundler
bundle install

cp build-scripts/database.yml config/

# generate default settings
bundle exec rake radvent:generate_default_settings

# run redmine database migrations
rm -f db/radvent.sqlite3
bundle exec rake db:create
bundle exec rake db:migrate





