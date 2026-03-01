#!/bin/bash

set -e

cd `dirname $0`
. env.sh
cd ..


echo "Running RuboCop..."
bundle exec rubocop --parallel

echo "Running YARD documentation check..."
bundle exec yard stats --list-undoc

echo "Running ESLint..."
yarn lint

echo "All lint checks passed!"
