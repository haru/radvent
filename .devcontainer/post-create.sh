#!/bin/sh

bundle install
bundle exec rake radvent:generate_default_settings
cp /database.yml /workspace/config/database.yml
bundle exec rake db:setup
yarn