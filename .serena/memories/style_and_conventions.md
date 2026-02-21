# Code Style and Conventions

## Ruby
- Formatter: rufo with single quotes (.rufo config)
- Views: HAML (not ERB)
- Generators: RSpec with FactoryBot, controller specs enabled, view/helper/routing specs disabled

## Frontend
- JavaScript: ES6+ modules via Webpacker
- CSS: SCSS with Bootstrap 5 (mdb-ui-kit)
- jQuery used for DOM manipulation
- Turbolinks for page transitions

## Testing
- RSpec for all tests
- FactoryBot for test data
- SimpleCov for coverage (output to coverage/)
