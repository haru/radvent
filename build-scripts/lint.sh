#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..


echo "Running RuboCop..."
bundle exec rubocop --parallel

echo "Running YARD documentation check..."
set +e
bundle exec yard stats --list-undoc --no-save | grep "100.00%" > /dev/null
if [ $? -ne 0 ]; then
  echo "YARD documentation coverage is below 100%. See report above." >&2
  exit 1
fi
set -e
echo "All objects are documented"

echo "Running ESLint..."
yarn lint

echo "All lint checks passed!"
