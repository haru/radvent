source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.2.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 8.1.0'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '>= 2.0'
# Use Puma as the app server
gem 'puma', '>= 6.0'
# JavaScript bundling with esbuild
gem 'jsbundling-rails', '~> 1.3'
# CSS bundling with sass
gem 'cssbundling-rails', '~> 1.4'
# Hotwire Turbo for SPA-like page navigation
gem 'turbo-rails', '~> 2.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.18', require: false

# Use Sprockets for asset pipeline
gem 'sprockets-rails', '~> 3.5'
# SCSS compilation for Sprockets
gem 'sassc-rails', '~> 2.1'

group :development, :test do
  gem 'debug', '~> 1.11', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  gem 'rack-mini-profiler', '~> 4.0'
  gem 'listen', '~> 3.3'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver', '~> 4.41'
  gem 'rspec-rails', '~> 8.0'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'simplecov', '~> 0.22'
  gem 'simplecov-lcov', '~> 0.9'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'haml-rails', '~> 3.0'
gem 'marked-rails', '~> 9.1'
gem 'devise', '~> 5.0'
gem 'devise-i18n', '~> 1.16'
gem 'devise-i18n-views', '~> 0.3'
gem 'devise-bootstrap-views', '~> 1.1'
gem 'bootstrap_form', '~> 5.6'
gem 'http_accept_language', '~> 2.1'
gem 'i18n_generators', '~> 2.2'
gem 'carrierwave', '~> 3.0'

# if you don't need mysql, use "--without mysql" option.
group :mysql do
  gem 'mysql2', '~> 0.5'
end

# if you don't need postgres, use "--without postgres" option.
group :postgres do
  gem 'pg', '~> 1.1'
end
