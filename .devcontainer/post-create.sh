#!/bin/sh

curl -LsSf https://astral.sh/uv/install.sh | sh
bundle install
if [ ! -f workspace/config/secrets.yml ]
then
  bundle exec rake radvent:generate_default_settings
fi
cp /database.yml /workspace/config/database.yml
bundle exec rake db:migrate
bundle exec rake db:migrate RAILS_ENV=test
yarn