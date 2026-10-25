# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'simplecov'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = 'coverage/lcov.info'
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::LcovFormatter,
                                                                 SimpleCov::Formatter::HTMLFormatter
                                                                 # Coveralls::SimpleCov::Formatter
                                                               ])

SimpleCov.start 'rails'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'devise'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
require Rails.root.join('spec/support/board_item_world')
require Rails.root.join('spec/support/breadcrumb_helpers')

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

PROTECTED_UPLOAD_TEST_ROOT = Rails.root.join('tmp/test_protected_uploads')
Rails.application.config.x.protected_upload_root = PROTECTED_UPLOAD_TEST_ROOT
# Legacy images live under the CarrierWave root; keep specs away from the real public/uploads.
LEGACY_UPLOAD_TEST_ROOT = Rails.root.join('tmp/test_public')
CarrierWave.root = LEGACY_UPLOAD_TEST_ROOT.to_s

# Where an attachment's image directory lives in each upload area.
module UploadPathHelpers
  def legacy_upload_dir(attachment)
    LEGACY_UPLOAD_TEST_ROOT.join(attachment.image.store_dir)
  end

  def protected_upload_dir(attachment)
    PROTECTED_UPLOAD_TEST_ROOT.join(attachment.image.store_dir)
  end
end

RSpec.configure do |config|
  # Clear leftovers from an aborted run too, since reused record ids would otherwise hit stale files.
  config.before(:suite) do
    FileUtils.rm_rf(PROTECTED_UPLOAD_TEST_ROOT)
    FileUtils.rm_rf(LEGACY_UPLOAD_TEST_ROOT)
  end

  config.after(:suite) do
    FileUtils.rm_rf(PROTECTED_UPLOAD_TEST_ROOT)
    FileUtils.rm_rf(LEGACY_UPLOAD_TEST_ROOT)
  end

  config.include UploadPathHelpers

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join('spec/fixtures').to_s]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
  config.include FactoryBot::Syntax::Methods
  config.infer_base_class_for_anonymous_controllers = true
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include BreadcrumbHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
end
