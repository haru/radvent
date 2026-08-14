# Suggested Commands

## Setup
```bash
bundle install
yarn install
bundle exec rake radvent:generate_default_settings
bundle exec rake db:create db:migrate
```

## Running
```bash
bundle exec rails s
```

## Testing
```bash
bundle exec rspec spec                         # all tests
bundle exec rspec spec/models/                 # model specs
bundle exec rspec spec/controllers/            # controller specs
bundle exec rspec spec/models/user_spec.rb     # single file
bundle exec rspec spec/models/user_spec.rb:42  # specific line
```

## Assets
```bash
bundle exec rake assets:precompile
```

## Formatting
- Ruby: rufo (single quotes, config in .rufo)

## System Utils
- git, ls, cd, grep, find (standard Linux)
