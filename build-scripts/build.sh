#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..


# build JS/CSS assets required by the asset pipeline during controller specs
RAILS_ENV=test bundle exec rake assets:precompile

# run tests
# bundle exec rake TEST=test/unit/role_test.rb

bundle exec rspec spec
