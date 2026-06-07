# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap"
Bootsnap.setup(
  cache_dir: "#{__dir__}/../tmp/cache",
  development_mode: ENV['RAILS_ENV'] == 'development',
  load_path_cache: true,
  compile_cache_iseq: !(defined?(Coverage) && Coverage.running?),
  compile_cache_yaml: true
)
