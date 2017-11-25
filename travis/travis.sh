#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..


# run tests
# bundle exec rake TEST=test/unit/role_test.rb
bundle exec rspec spec
bundle exec codeclimate-test-reporter
