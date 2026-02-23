#!/bin/sh
set -e

## cd to script directory
cd "$(dirname "$0")"
cd ..

cat .devcontainer/bashrc >> ~/.bashrc

curl -LsSf https://astral.sh/uv/install.sh | sh
curl -fsSL https://claude.ai/install.sh | bash

# bundle config set --local path vendor/bundle
bundle install

if [ ! -f config/secrets.yml ]
then
  bundle exec rake radvent:generate_default_settings
fi
cp .devcontainer/database.yml config/database.yml
bundle exec rake db:migrate
bundle exec rake db:migrate RAILS_ENV=test
npm install -g yarn
yarn
bundle exec rake assets:precompile
