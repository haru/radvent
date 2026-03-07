#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..


echo "Running RuboCop..."
bundle exec rubocop --parallel

echo "Running YARD documentation check..."
set +e
yard_output=$(bundle exec yard stats --list-undoc --no-save 2>&1)
echo "$yard_output" | grep "100.00%" > /dev/null
if [ $? -ne 0 ]; then
  echo "$yard_output" >&2
  echo "YARD documentation coverage is below 100%." >&2
  exit 1
fi
set -e
echo "All objects are documented"

echo "Running ESLint..."
yarn lint

echo "All lint checks passed!"
