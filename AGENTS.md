# AGENTS.md - Guidelines for Agentic Coding in Radvent

## ABSOLUTE RULES (CRITICAL)

**NEVER commit or push changes without explicit user permission**
- Do NOT run `git commit` under any circumstances
- Do NOT run `git push` under any circumstances
- Do NOT create pull requests under any circumstances
- Only show changes with `git diff` after user approves
- Wait for explicit user confirmation before ANY git operations

**NEVER decide commit message without user approval**
- Let user write the commit message
- Do not automatically generate or suggest commit messages
- Ask user for commit message before running `git commit`

## Git Flow (Branching Model)

This project uses **Git Flow** branching model (also known as A successful git branching model).

### Branch Structure
- `main`: Production-ready code. Never commit directly to main.
- `develop`: Integration branch. Never commit directly to develop.
- `bugfix/*`: Feature branches for bug fixes.
- `feature/*`: Feature branches for new features.

### Development Workflow
1. Create a `bugfix/` or `feature/` branch from `develop`
2. Make changes, test, and commit to your branch
3. Push branch to remote: `git push -u origin branch-name`
4. Create pull request from your branch to `develop`
5. Merge PR into `develop` after review
6. Never commit or push directly to `main` or `develop`

### Example Commands
```bash
git checkout develop
git pull origin develop
git checkout -b bugfix/your-fix
# Make changes, test, commit
git push -u origin bugfix/your-fix
# Create PR from bugfix/your-fix to develop
```

## Build, Lint, and Test Commands

### Setup
```bash
bundle install && yarn install
bundle exec rake radvent:generate_default_settings
bundle exec rake db:create db:migrate
```

### Development Server
```bash
bundle exec rails s
```

### Testing
```bash
bundle exec rspec spec                         # All tests
bundle exec rspec spec/models/                 # Model specs
bundle exec rspec spec/controllers/            # Controller specs
bundle exec rspec spec/models/user_spec.rb     # Single file
bundle exec rspec spec/models/user_spec.rb:42  # Specific test (line number)
```
Coverage reports generated to `coverage/` (HTML and LCOV formats).

### Asset Build
```bash
yarn build                                     # JS via esbuild
yarn build:css                                 # SCSS compilation
yarn copy:fonts                                # Copy font files
bundle exec rake assets:precompile             # Production assets
```

### Code Formatting
```bash
# Ruby - rufo with single quotes (configured in .rufo)
rufo app/ spec/ lib/                           # Format Ruby files
```

## Code Style Guidelines

### Ruby/Rails Conventions
- **Quotes**: Use single quotes by default (rufo config)
- **Strings**: No comments unless explicitly requested
- **Indentation**: 2 spaces (Ruby standard)
- **Method visibility**: Use `public`/`private`/`protected` keywords (see event.rb:19)
- **Validation**: Place validations at top of model classes
- **Custom validations**: Define as private methods with `validate :method_name`
- **Model relationships**: Standard ActiveRecord associations
- **Callbacks**: Use standard Rails patterns where needed

### Controllers
- **Layouts**: Set with `layout 'admin'` or `layout 'application'`
- **Filters**: Use `before_action` with `only`/`except` constraints
- **Authorization**: 
  ```ruby
  before_action :authenticate_user!
  admin_user!                              # ApplicationController helper
  ```
- **Error rendering**: Use `render_404` or `render_403` from ApplicationController
- **Params**: Strong params pattern: `params.require(:resource).permit(:field1, :field2)`

### Views (HAML Only - Never ERB)
- **File extension**: `.html.haml`
- **Pattern**:
  ```haml
  - content_for(:jumbotron) do
    %div.jumbotron= @event.title
  = render "partial", item: @item
  = t("views.events.show.some_key")
  ```
- **Interpolation**: Use `#{}` for Ruby interpolation
- **Nested content**: Indent properly within blocks
- **i18n**: Always use `t()` for user-facing strings

### Naming Conventions
- **Models**: Singular, PascalCase (e.g., `AdventCalendarItem`)
- **Controllers**: Plural, PascalCase (e.g., `EventsController`)
- **Tables**: Plural, snake_case (e.g., `advent_calendar_items`)
- **Views**: Match controller/action (e.g., `events/show.html.haml`)
- **Routes**: RESTful resources with custom routes as needed
- **Private methods**: Snake_case (e.g., `find_event_by_name`)

### Error Handling
- **404 errors**: Call `render_404` helper (ApplicationController)
- **403 errors**: Call `render_403` or `admin_user!` helper
- **Validation errors**: Use standard Rails validation with i18n keys
- **Not found records**: Check and render 404 (see events_controller.rb:70)

### Testing Patterns
- **Framework**: RSpec + FactoryBot
- **FactoryBot**: Call `create(:model)` or `build(:model)` directly (no prefix)
- **Devise auth**: `sign_in @user` (auto-included in controller specs)
- **Setup**: Often use `Model.destroy_all` in `before` blocks
- **Date mocking**: `allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))`
- **Controller tests**: Use standard `get`/`post`/`put`/`delete` with params hash
- **Model tests**: Use `describe` blocks with `it` or `before` hooks

### Project-Specific Gotchas

**Critical: Event routing uses name, not ID**
```ruby
# CORRECT
get 'events/:name' => 'events#show', as: :show_event
show_event_path(event.name)  # Use event.name, not event.id

# INCORRECT
event_path(event)  # This won't work!
```

**AdventCalendarItem.date is Integer, not Date**
- Column type: Integer (1-31), not Date/DateTime
- Query with `.where(date: date.day)` pattern

**Comment model has no user_id**
- Stores `user_name` as string only
- No relationship to User model

**Layout switching**
- Admin pages: `layout 'admin'` in controller
- EventsController#show overrides with `render layout: 'application'`

**i18n Configuration**
- Default locale: `:ja` (Japanese)
- Timezone: `Tokyo`
- Auto-detect locale: `http_accept_language` gem

**Generators Config**
- Test framework: RSpec with controller specs only
- Fixture replacement: FactoryBot in `spec/factories/`
- View/helper/routing specs: Disabled in config

### Database
- **Dev default**: SQLite3
- **Production**: MySQL 5.7+ or PostgreSQL (via env vars)
- **Env vars**: `DB`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`

### Generator Settings (config/application.rb)
- Controller specs: enabled
- View specs: disabled
- Helper specs: disabled
- Routing specs: disabled
- Request specs: disabled

When working on this codebase, follow these conventions to maintain consistency with existing code patterns.
