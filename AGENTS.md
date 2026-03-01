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

```bash
git checkout develop
git pull origin develop
git checkout -b bugfix/your-fix
# Make changes, test, commit
git push -u origin bugfix/your-fix
# Create PR from bugfix/your-fix to develop
```

## Project Overview

Radvent is a Qiita-style Advent Calendar web application (Japanese-focused). Users can create events, publish markdown articles on specific calendar dates, and interact via likes and comments. Built with Ruby on Rails and esbuild.

### Tech Stack
- **Backend**: Ruby (>= 3.0) / Rails 8.1, Puma, Devise (auth)
- **Frontend**: esbuild, HAML templates, PostCSS, Bootstrap 5 (mdb-ui-kit), @hotwired/stimulus
- **Markdown editor**: EasyMDE (easy-markdown-editor) with toolbar, side-by-side preview, image upload, and DOMPurify sanitization
- **Markdown rendering**: Marked.js with highlight.js for syntax highlighting
- **File uploads**: CarrierWave
- **Database**: SQLite3 (dev default), MySQL 5.7+, or PostgreSQL (configurable via env vars)

### Key Models and Relationships

```
Event ──< AdventCalendarItem >── User
               │
               └──1 Item ──< Comment
                      └──< Like >── User
```

- `User` — Devise-based auth, has admin role, has many items/likes/comments
- `Event` — Advent calendar event with start/end dates
- `AdventCalendarItem` — Calendar "slot" (date × event × user). The `date` column is **Integer** (1–31), not a Date type
- `Item` — Article with markdown body. `belongs_to :advent_calendar_item` (unique constraint)
- `Comment` — Has **no `user_id` column**; stores `user_name` as a string only
- `Like` — Belongs to user and item
- `Attachment` — File uploads via CarrierWave, belongs to `AdventCalendarItem`

### Key Files

| Purpose | Path |
|---|---|
| Models | `app/models/` — `advent_calendar_item.rb`, `item.rb`, `event.rb`, `user.rb` |
| Controllers | `app/controllers/application_controller.rb` |
| Routing | `config/routes.rb` |
| Schema | `db/schema.rb` |
| Factories | `spec/factories/` |
| i18n | `config/locales/` |
| JS Controllers | `app/javascript/controllers/` — Stimulus controllers |
| CSS Entry Point | `app/javascript/stylesheets/application.css` |

## Build, Lint, and Test Commands

### Setup
```bash
bundle install && yarn install
bundle exec rake radvent:generate_default_settings  # generates config/database.yml, config/secrets.yml, config/initializers/devise.yml
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
Coverage reports are generated to `coverage/` (HTML and LCOV formats).

### Asset Build
```bash
yarn build                                     # JS via esbuild
yarn build:css                                 # PostCSS compilation
yarn copy:fonts                                # Copy font files
bundle exec rake assets:precompile             # Production assets
```

### Code Formatting
```bash
rufo app/ spec/ lib/                           # Format Ruby files (single quotes, configured in .rufo)
```

### Code Quality Checks (MUST run before committing)
```bash
bundle exec rubocop                             # Ruby linting
bundle exec rubocop -a                          # Auto-fix Ruby issues
bundle exec yard --list --no-save               # YARD documentation check
yarn lint                                       # JavaScript linting
yarn lint:fix                                   # Auto-fix JavaScript issues
bash build-scripts/lint.sh                      # Run all lint checks
```

## Code Style Guidelines

### Ruby/Rails Conventions
- **Quotes**: Use single quotes by default (rufo config)
- **Indentation**: 2 spaces (Ruby standard)
- **Method visibility**: Use `public`/`private`/`protected` keywords explicitly
- **Validation**: Place validations at top of model classes
- **Custom validations**: Define as private methods with `validate :method_name`
- **Callbacks**: Use standard Rails patterns where needed

### Controllers
- **Layouts**: Set with `layout 'admin'` or `layout 'application'`
- **Filters**: Use `before_action` with `only`/`except` constraints
- **Authorization**:
  ```ruby
  before_action :authenticate_user!
  admin_user!                              # ApplicationController helper — renders 403 for non-admins
  ```
- **Error rendering**: Use `render_404` or `render_403` from ApplicationController
- **Params**: Strong params pattern — `params.require(:resource).permit(:field1, :field2)`

### Views (HAML Only — Never ERB)
- **File extension**: `.html.haml`
- **Pattern**:
  ```haml
  - content_for(:jumbotron) do
    %div.jumbotron= @event.title
  = render "partial", item: @item
  = t("views.events.show.some_key")
  ```
- **Interpolation**: Use `#{}` for Ruby interpolation
- **i18n**: Always use `t()` for user-facing strings

### Frontend JavaScript (Stimulus)
- **Framework**: @hotwired/stimulus — do NOT use jQuery
- **Naming**: `{name}_controller.js` (snake_case files, kebab-case `data-controller` values)
- **Registration**: `app/javascript/controllers/index.js` — add new controllers here
- **Available controllers**:
  - `markdown` — renders `data-markdown-body-value` as Markdown via marked + DOMPurify
  - `comment` — renders comment text content as Markdown (with `data-rendered` guard against Turbo double-render)
  - `editor` — EasyMDE editor with image upload; values: `upload-path`, `upload-error`, `network-error`
  - `datatable` — initialises simple-datatables on a `<table>` element
  - `popover` — initialises MDB Popover
- **Turbo guard**: For re-entrant `connect()`, check `this.element.dataset.rendered === 'true'` before re-processing
- **CSS**: PostCSS pipeline (`yarn build:css`); source at `app/javascript/stylesheets/application.css`. Do NOT use `.scss` files.

```javascript
// Adding a new controller — append to app/javascript/controllers/index.js:
application.register('my-feature', MyFeatureController)
```

```haml
/ HAML usage example
%div{data: {controller: 'markdown', markdown_body_value: item.body}}
```

### Naming Conventions
- **Models**: Singular, PascalCase (e.g., `AdventCalendarItem`)
- **Controllers**: Plural, PascalCase (e.g., `EventsController`)
- **Tables**: Plural, snake_case (e.g., `advent_calendar_items`)
- **Views**: Match controller/action (e.g., `events/show.html.haml`)
- **Private methods**: Snake_case (e.g., `find_event_by_name`)

### Testing Patterns
- **Framework**: RSpec + FactoryBot
- **FactoryBot**: Call `create(:model)` or `build(:model)` directly (no prefix)
- **Devise auth**: `sign_in @user` (auto-included via `Devise::Test::ControllerHelpers`)
- **Setup**: Often use `Model.destroy_all` in `before` blocks
- **Date mocking**: `allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))`

```ruby
RSpec.describe ItemsController, type: :controller do
  before do
    @user = create(:user)
    sign_in @user
  end
end
```

### Error Handling
- **404 errors**: Call `render_404` helper (ApplicationController)
- **403 errors**: Call `render_403` or `admin_user!` helper
- **Validation errors**: Use standard Rails validation with i18n keys

## Project-Specific Gotchas

**Critical: Event routing uses name, not ID**
```ruby
# CORRECT
get 'events/:name' => 'events#show', as: :show_event
show_event_path(event.name)  # Use event.name, not event.id

# INCORRECT
event_path(event)  # This won't work!
```

**AdventCalendarItem.date is Integer, not Date**
- Column type: Integer (1–31), not Date/DateTime
- Query with `.where(date: date.day)` pattern

**Comment model has no user_id**
- Stores `user_name` as string only
- No relationship to User model

**Layout switching**
- Admin pages: `layout 'admin'` in controller
- `EventsController#show` overrides with `render layout: 'application'`

**i18n / Timezone**
- Default locale: `:ja` (Japanese), with English support via `http_accept_language` gem
- Timezone: `Tokyo` (`config.time_zone = 'Tokyo'`)
- App settings generated by `rake radvent:generate_default_settings` into `config/settings/`
- Default admin login: `admin@example.com` / `adminadmin`

**Generator settings (config/application.rb)**
- Controller specs: enabled
- View / Helper / Routing / Request specs: disabled
- Fixture replacement: FactoryBot in `spec/factories/`

### Database
- **Dev default**: SQLite3
- **Production**: MySQL 5.7+ or PostgreSQL
- **Env vars**: `DB` (sqlite3/mysql/postgres), `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, `RADVENT_TITLE`

## Docker / CI

- `docker-compose.yml` at root runs PostgreSQL + Radvent
- `.devcontainer/` provides VS Code dev container setup with Ruby 3.1 and PostgreSQL
- **CI**: GitHub Actions matrix tests against Ruby 3.0 & 3.1 with SQLite3, MySQL, and PostgreSQL

---

When working on this codebase, follow these conventions to maintain consistency with existing code patterns.
