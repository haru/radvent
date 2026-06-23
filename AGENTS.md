# AGENTS.md — Radvent

## Absolute Rules

- **NEVER commit, push, or create PRs** without explicit user permission.
- **NEVER decide commit messages** — ask the user.
- **Language**: All commit messages and source code comments must be written in **English**.
- **TDD is mandatory**: Write tests before implementation. Red → Green → Refactor.
- **Lint must pass** before a task is considered complete: `sh build-scripts/lint.sh`.
- **Test coverage ≥ 90%** — reports at `coverage/`.

## Commands

```bash
# Setup (first time)
bundle install && yarn install
bundle exec rake radvent:generate_default_settings   # generates config/database.yml, secrets, devise
bundle exec rake db:create db:migrate

# Dev server
bundle exec rails s

# Test
bundle exec rspec spec                              # all tests
bundle exec rspec spec/models/user_spec.rb           # single file
bundle exec rspec spec/models/user_spec.rb:42        # specific test line

# Lint (run ALL before completing any task)
sh build-scripts/lint.sh                             # rubocop + YARD 100% + eslint
bundle exec rubocop -a                               # auto-fix Ruby
yarn lint:fix                                       # auto-fix JS

# Format
rufo app/ spec/ lib/                                 # Ruby formatter (single quotes enforced)

# Asset build
yarn build                                           # JS (esbuild)
yarn build:css                                       # CSS (PostCSS)
```

## Architecture

Ruby on Rails 8.1 + esbuild + Stimulus. Japanese-focused Advent Calendar app (Qiita-style).

**Key model relationships:**
```
Event ──< AdventCalendarItem >── User
               │
               └──1 Item ──< Comment
                      └──< Like >── User
```

- `AdventCalendarItem` — calendar slot. `date` column is **Integer (1–31)**, not Date.
- `Comment` — stores `user_name` as string only; **no `user_id`** column.
- `Board` — two types: `top` (system) and `user` (slug-based). Has `Permissionable` concern with `visibility` enum.

## Gotchas (non-obvious, agent will likely get wrong)

| Gotcha | Detail |
|--------|--------|
| **Event routing uses `name`, not ID** | `show_event_path(event.name)` — never `event_path(event)` |
| **Board routing uses `board_id` slug** | `resources :boards, param: :board_id` — use `board_path(board.board_id)` |
| **AdventCalendarItem.date is Integer** | Query with `.where(date: date.day)` |
| **Comment has no user_id** | Stores `user_name` as string only |
| **Views are HAML only** | Never create `.erb` files. Use `.html.haml`. |
| **JS framework is Stimulus** | Do NOT use jQuery. Register controllers in `app/javascript/controllers/index.js`. |
| **CSS is PostCSS only** | Source: `app/javascript/stylesheets/application.css`. No `.scss` files. |
| **Stimulus Turbo guard** | In `connect()`, check `this.element.dataset.rendered === 'true'` before re-processing. |
| **Layout switching** | Admin: `layout 'admin'`. `EventsController#show` overrides with `render layout: 'application'`. |
| **Migrations: always generate** | `rails generate migration ...` — never write by hand (cross-DB portability). If raw SQL needed, use `CURRENT_TIMESTAMP`. |
| **i18n** | Default locale `:ja`, timezone `Tokyo`. Always use `t()` for user-facing strings. |
| **Generator settings** | Controller specs enabled; view/helper/routing/request specs disabled. FactoryBot only. |
| **Lint includes YARD 100%** | `build-scripts/lint.sh` fails if YARD docs are not 100%. Document all public methods. |
| **Lint sets RAILS_ENV=test** | `build-scripts/env.sh` exports `RAILS_ENV=test`. |
| **CI runs assets:precompile** | `build-scripts/build.sh` precompiles assets before tests — controller specs may need compiled assets. |
| **No easy fallbacks** | Surface errors explicitly — never silently swallow them behind defaults. |

## Style

- **Ruby**: Single quotes (rufo), 2-space indent, explicit `public`/`private`/`protected`.
- **FactoryBot**: `create(:model)` / `build(:model)` directly (no prefix).
- **Devise auth in tests**: `sign_in @user` (auto-included via `Devise::Test::ControllerHelpers`).
- **Date mocking**: `allow(Time.zone).to receive(:today).and_return(Date.new(2015, 12, 2))`.
- **Error handling**: `render_not_found` / `render_forbidden` / `admin_user!` from ApplicationController.
- **Commit messages**: Conventional commits format (`feat:`, `fix:`, `refactor:`, etc.). English only.

## Git Flow

- Branches: `main` (production), `develop` (integration), `feature/*`, `bugfix/*`.
- Never commit directly to `main` or `develop`.
- Create PRs from feature/bugfix branches into `develop`.

## Database

- Dev: SQLite3. Production: MySQL 5.7+ or PostgreSQL.
- Env vars: `DB`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`.
- CI matrix: Ruby 3.3–4.0 × sqlite3/mysql/postgres.

## Extended Agent Rules

Detailed workflow rules live in `.claude/rules/`:
- [development-workflow.md](.claude/rules/development-workflow.md) — Research → plan → TDD → review pipeline
- [git-workflow.md](.claude/rules/git-workflow.md) — Commit message format, PR workflow

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
