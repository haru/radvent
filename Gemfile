source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '>= 2.3.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# Use thin instead of WEBrick
gem 'thin'

group :development do
  gem 'pry-rails'
  gem 'tapp'
  gem 'better_errors'
end

group :test do
  gem "rspec-rails", '~> 3.0'
  gem "factory_girl_rails", "~> 4.5.0"
  gem 'rails-controller-testing'
  gem 'simplecov'
  gem "codeclimate-test-reporter", require: false
end

gem 'haml-rails'

gem 'marked-rails'

gem 'carrierwave'

gem 'font-awesome-sass'

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

gem 'coffee-script-source', platforms: [:mingw, :mswin, :x64_mingw]
gem 'bcrypt-ruby', '~> 3.0.0'

gem 'devise'
gem 'devise-i18n'
gem 'devise-i18n-views'
gem 'devise-bootstrap-views'

gem 'bootstrap', '~> 4.0.0.beta2.1'
gem 'jquery-datatables-rails', '~> 3.4.0'
gem 'bootstrap_form'
gem 'bootstrap-glyphicons'

#gem 'bootstrap-material-design'

gem 'i18n_generators'

source 'http://insecure.rails-assets.org' do
  gem 'rails-assets-bootstrap-material-design', '~> 4.0.0.beta.4'
end

gem 'http_accept_language'
